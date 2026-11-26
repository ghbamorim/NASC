import asyncio

import httpx
from telegram import Bot
from telegram.error import BadRequest

from app.core.exceptions import AudioProcessingError
from app.core.settings import settings
from app.schemas.channel_messages import VoiceMetadata


class TelegramAudioService:
    async def _download_file(
        self,
        file_url: str,
        max_size: int,
    ) -> bytes:
        audio = bytearray()

        try:
            async with (
                httpx.AsyncClient(
                    timeout=settings.telegram_voice_download_timeout_seconds,
                ) as client,
                client.stream("GET", file_url) as response,
            ):
                if response.status_code in (400, 404, 410):
                    raise AudioProcessingError(
                        "Não foi possível recuperar o áudio enviado."
                    )

                response.raise_for_status()

                async for chunk in response.aiter_bytes(
                    chunk_size=64 * 1024,
                ):
                    if len(audio) + len(chunk) > max_size:
                        raise AudioProcessingError(
                            "O áudio excede o tamanho máximo permitido."
                        )

                    audio.extend(chunk)

        except httpx.HTTPStatusError as exc:
            raise RuntimeError(
                f"Telegram audio download failed: HTTP {exc.response.status_code}."
            ) from None

        except httpx.RequestError as exc:
            raise RuntimeError(
                f"Telegram audio download failed: {type(exc).__name__}."
            ) from None

        if not audio:
            raise AudioProcessingError("O arquivo de áudio está vazio.")

        return bytes(audio)

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

                if not file.file_path:
                    raise AudioProcessingError(
                        "Não foi possível localizar o arquivo de áudio."
                    )

                return await self._download_file(
                    file_url=file.file_path,
                    max_size=max_size,
                )
