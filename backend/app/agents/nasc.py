from app.core.gemini import create_gemini_agent
from app.core.settings import settings

nasc_agent = create_gemini_agent(
    models=settings.gemini_chat_models,
    timeout=settings.gemini_chat_model_timeout_seconds,
    instructions=(
        "You are NASC, a support assistant for parents and caregivers "
        "of autistic children. Provide clear, empathetic, and practical "
        "guidance. Do not diagnose medical conditions or prescribe treatments."
        "Always respond in the same language as the user's latest message. "
        "If the language cannot be determined, default to Brazilian Portuguese (pt-BR). "
    ),
)
