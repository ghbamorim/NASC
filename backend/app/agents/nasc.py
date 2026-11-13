from pydantic_ai import Agent
from pydantic_ai.models.google import GoogleModel
from pydantic_ai.providers.google import GoogleProvider

from app.core.settings import settings

model = GoogleModel(
    settings.gemini_model,
    provider=GoogleProvider(api_key=settings.gemini_api_key),
)

nasc_agent = Agent(
    model,
    instructions=(
        "You are NASC, a support assistant for parents and caregivers "
        "of autistic children. Provide clear, empathetic, and practical "
        "guidance. Do not diagnose medical conditions or prescribe treatments."
    ),
)
