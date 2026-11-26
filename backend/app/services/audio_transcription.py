import asyncio

from pydantic_ai import BinaryContent

from app.agents.transcription import transcription_agent
from app.core.exceptions import AudioProcessingError
from app.core.settings import settings


class AudioTranscriptionService:
    async def transcribe(self, audio: bytes) -> str:
        async with asyncio.timeout(settings.gemini_transcription_timeout_seconds):
            result = await transcription_agent.run(
                [
                    BinaryContent(
                        data=audio,
                        media_type="audio/ogg",
                    )
                ]
            )

        transcription = result.output.strip()

        if not transcription:
            raise AudioProcessingError(
                "Não foi possível identificar uma fala inteligível no áudio."
            )

        return transcription
