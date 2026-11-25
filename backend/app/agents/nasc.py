from google import genai
from google.genai.types import HttpOptions, HttpRetryOptions
from pydantic_ai import Agent
from pydantic_ai.capabilities import ModelFallback
from pydantic_ai.exceptions import ModelAPIError
from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider

from app.core.settings import settings

client = genai.Client(
    api_key=settings.gemini_api_key,
    http_options=HttpOptions(
        retry_options=HttpRetryOptions(attempts=1),
    ),
)

provider = GoogleProvider(client=client)

model = GoogleModel(
    settings.gemini_model,
    provider=provider,
)

fallback_models = [
    GoogleModel(model_name, provider=provider)
    for model_name in settings.gemini_fallback_models
]

nasc_agent = Agent(
    model,
    model_settings={
        "request_timeout": 30,
    },
    capabilities=[
        ModelFallback(
            *fallback_models,
            fallback_on=(ModelAPIError,),
            sticky=False,
        ),
    ],
    instructions=(
        "You are NASC, a support assistant for parents and caregivers "
        "of autistic children. Provide clear, empathetic, and practical "
        "guidance. Do not diagnose medical conditions or prescribe treatments."
    ),
)
