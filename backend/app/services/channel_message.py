from datetime import UTC, datetime
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.repositories.channel_conversation import ChannelConversationRepository
from app.services.channel_user import ChannelUserService
from app.services.chat import ChatService


class ChannelMessageService:
    def __init__(
        self,
        db: AsyncSession,
        channel_conversation_repository: ChannelConversationRepository | None = None,
    ) -> None:
        self.db = db
        self.channel_conversation_repository = (
            channel_conversation_repository or ChannelConversationRepository(db)
        )
        self.channel_user_service = ChannelUserService(db)
        self.chat_service = ChatService(db)

    async def process(
        self,
        channel: str,
        external_user_id: str,
        external_chat_id: str,
        external_message_id: str,
        message_date: int,
        message: str,
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

        parts = message.strip().split(maxsplit=1)
        command = parts[0] if parts else ""

        if command == "/start":
            if channel_user is not None:
                return None, "Sua conta já está vinculada ao NASC."

            if len(parts) == 1:
                return None, "Solicite um link de vinculação ao administrador."

            token = parts[1]

            try:
                await self.channel_user_service.link(
                    channel=channel,
                    external_user_id=external_user_id,
                    token=token,
                )
            except ValueError:
                return (
                    None,
                    "Não foi possível vincular sua conta. Solicite um novo link.",
                )

            return None, "Sua conta foi vinculada ao NASC com sucesso."

        if channel_user is None or user is None:
            return None, "Sua conta não está vinculada ao NASC."

        received_at = datetime.fromtimestamp(message_date, tz=UTC)

        if received_at < channel_user.created_at:
            return None, "Mensagem anterior à vinculação atual."

        if command.startswith("/"):
            return None, "Comando não reconhecido."

        conversation_id = (
            await self.channel_conversation_repository.get_conversation_id(
                channel_user_id=channel_user.id,
                external_chat_id=external_chat_id,
            )
        )

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
