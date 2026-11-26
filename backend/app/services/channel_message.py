from datetime import UTC, datetime
from typing import Literal
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AudioProcessingError
from app.models.channel_user import ChannelUser
from app.models.user import User
from app.repositories.channel_conversation import ChannelConversationRepository
from app.schemas.channel_messages import VoiceMetadata
from app.services.audio_transcription import AudioTranscriptionService
from app.services.channel_user import ChannelUserService
from app.services.chat import ChatService
from app.services.telegram_audio import TelegramAudioService


class ChannelMessageService:
    def __init__(
        self,
        db: AsyncSession,
        channel_conversation_repository: ChannelConversationRepository | None = None,
        telegram_audio_service: TelegramAudioService | None = None,
        audio_transcription_service: AudioTranscriptionService | None = None,
    ) -> None:
        self.db = db
        self.channel_conversation_repository = (
            channel_conversation_repository or ChannelConversationRepository(db)
        )
        self.channel_user_service = ChannelUserService(db)
        self.chat_service = ChatService(db)
        self.telegram_audio_service = telegram_audio_service or TelegramAudioService()
        self.audio_transcription_service = (
            audio_transcription_service or AudioTranscriptionService()
        )

    @staticmethod
    def get_response_type(
        message_type: Literal["text", "voice"],
    ) -> Literal["text"]:
        return "text"

    async def _process_command(
        self,
        channel: str,
        external_user_id: str,
        channel_user: ChannelUser | None,
        message: str,
    ) -> str | None:
        parts = message.strip().split(maxsplit=1)
        command = parts[0] if parts else ""

        if command != "/start":
            return None

        if channel_user is not None:
            return "Sua conta já está vinculada ao NASC."

        if len(parts) == 1:
            return "Solicite um link de vinculação ao administrador."

        token = parts[1]

        try:
            await self.channel_user_service.link(
                channel=channel,
                external_user_id=external_user_id,
                token=token,
            )
        except ValueError:
            return "Não foi possível vincular sua conta. Solicite um novo link."

        return "Sua conta foi vinculada ao NASC com sucesso."

    async def process(
        self,
        channel: str,
        external_user_id: str,
        external_chat_id: str,
        external_message_id: str,
        message_date: int,
        message_type: Literal["text", "voice"],
        message: str | None,
        voice: VoiceMetadata | None,
    ) -> tuple[UUID | None, str]:
        if channel != "telegram":
            return None, "Canal não suportado."

        if external_user_id != external_chat_id:
            return None, "Utilize uma conversa privada com o bot."

        await self.channel_conversation_repository.lock(
            channel=channel,
            external_chat_id=external_chat_id,
        )

        channel_user = await self.channel_user_service.get_by_external_user(
            channel=channel,
            external_user_id=external_user_id,
        )

        user = (
            await self.db.get(User, channel_user.user_id)
            if channel_user is not None
            else None
        )

        if channel_user is not None and (user is None or not user.is_active):
            return None, "Sua conta está inativa."

        if message_type == "text" and message is not None:
            command_response = await self._process_command(
                channel=channel,
                external_user_id=external_user_id,
                channel_user=channel_user,
                message=message,
            )

            if command_response is not None:
                return None, command_response

        if channel_user is None or user is None:
            return None, "Sua conta não está vinculada ao NASC."

        received_at = datetime.fromtimestamp(message_date, tz=UTC)

        if received_at < channel_user.created_at:
            return None, "Mensagem anterior à vinculação atual."

        if (
            message_type == "text"
            and message is not None
            and message.strip().startswith("/")
        ):
            return None, "Comando não reconhecido."

        conversation_id = (
            await self.channel_conversation_repository.get_conversation_id(
                channel_user_id=channel_user.id,
                external_chat_id=external_chat_id,
            )
        )

        if conversation_id is not None and message_type == "voice":
            existing_response = await self.chat_service.get_existing_response(
                conversation_id=conversation_id,
                user_id=user.id,
                external_message_id=external_message_id,
            )

            if existing_response is not None:
                return conversation_id, existing_response

        if message_type == "voice":
            if voice is None:
                raise ValueError("Voice metadata is required.")

            try:
                audio = await self.telegram_audio_service.download(voice)
                message = await self.audio_transcription_service.transcribe(audio)
            except AudioProcessingError as exc:
                return None, str(exc)

        if message is None:
            raise ValueError("Message content is required.")

        is_new_conversation = conversation_id is None

        conversation_id, response = await self.chat_service.chat(
            user_id=user.id,
            message=message,
            conversation_id=conversation_id,
            external_message_id=external_message_id,
        )

        if is_new_conversation:
            await self.channel_conversation_repository.create(
                channel_user_id=channel_user.id,
                external_chat_id=external_chat_id,
                conversation_id=conversation_id,
            )

        return conversation_id, response
