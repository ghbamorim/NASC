from typing import Annotated

from fastapi import Depends
from google import genai
from google.genai import types

from app.core.settings import settings


def get_gemini_client() -> genai.Client:
    return genai.Client(
        api_key=settings.gemini_api_key,
        http_options=types.HttpOptions(
            timeout=10000,
            retry_options=types.HttpRetryOptions(attempts=1),
        ),
    )


type GenAiClient = Annotated[genai.Client, Depends(get_gemini_client)]
