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


def create_gemini_agent(
    models: list[str],
    timeout: int,
    instructions: str,
) -> Agent[None, str]:
    model, *fallback_models = [
        GoogleModel(model_name, provider=provider) for model_name in models
    ]

    capabilities = (
        [
            ModelFallback(
                *fallback_models,
                fallback_on=(ModelAPIError, TimeoutError),
                sticky=False,
            )
        ]
        if fallback_models
        else []
    )

    return Agent(
        model,
        model_settings={
            "request_timeout": timeout,
        },
        capabilities=capabilities,
        instructions=instructions,
    )
