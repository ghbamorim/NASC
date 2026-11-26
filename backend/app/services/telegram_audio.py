import asyncio

from telegram import Bot
from telegram.error import BadRequest

from app.core.exceptions import AudioProcessingError
from app.core.settings import settings
from app.schemas.channel_messages import VoiceMetadata


class TelegramAudioService:
    async def download(self, voice: VoiceMetadata) -> bytes:
        if voice.duration > settings.telegram_voice_max_duration_seconds:
            raise AudioProcessingError("O áudio excede a duração máxima permitida.")

        if voice.mime_type not in (None, "audio/ogg"):
            raise AudioProcessingError("Formato de áudio não suportado.")

        max_size = settings.telegram_voice_max_size_bytes

        if voice.file_size is not None and voice.file_size > max_size:
            raise AudioProcessingError("O áudio excede o tamanho máximo permitido.")

        async with asyncio.timeout(settings.telegram_voice_download_timeout_seconds):
            async with Bot(token=settings.telegram_bot_token) as bot:
                try:
                    file = await bot.get_file(voice.file_id)
                except BadRequest as exc:
                    raise AudioProcessingError(
                        "Não foi possível recuperar o áudio enviado."
                    ) from exc

                if file.file_size is None:
                    raise AudioProcessingError(
                        "Não foi possível determinar o tamanho do áudio."
                    )

                if file.file_size > max_size:
                    raise AudioProcessingError(
                        "O áudio excede o tamanho máximo permitido."
                    )

                audio = await file.download_as_bytearray()

        if not audio:
            raise AudioProcessingError("O arquivo de áudio está vazio.")

        if len(audio) > max_size:
            raise AudioProcessingError("O áudio excede o tamanho máximo permitido.")

        return bytes(audio)
