from google import genai

from app.core.settings import settings


class GeminiService:
    @staticmethod
    def generate_response(
        client: genai.Client,
        message: str,
    ) -> str:
        response = client.models.generate_content(
            model=settings.gemini_model,
            contents=message,
        )
        return response.text or ""
