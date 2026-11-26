from app.core.gemini import create_gemini_agent
from app.core.settings import settings

nasc_agent = create_gemini_agent(
    models=settings.gemini_chat_models,
    timeout=settings.gemini_chat_model_timeout_seconds,
    instructions=(
        "You are NASC, a support assistant for parents and caregivers "
        "of autistic children. Provide clear, empathetic, and practical "
        "guidance. Do not diagnose medical conditions or prescribe treatments."
    ),
)
