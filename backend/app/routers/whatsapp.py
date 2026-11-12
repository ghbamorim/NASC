import hashlib
import hmac
import logging

from fastapi import APIRouter, HTTPException, Query, Request, Response, status
from fastapi.responses import PlainTextResponse

from app.core.settings import settings
from app.schemas.whatsapp import WhatsAppWebhook

logger = logging.getLogger("uvicorn.error")

router = APIRouter(prefix="/webhooks/whatsapp", tags=["whatsapp"])


@router.get("", response_class=PlainTextResponse)
async def verify_webhook(
    mode: str = Query(alias="hub.mode"),
    token: str = Query(alias="hub.verify_token"),
    challenge: str = Query(alias="hub.challenge"),
) -> str:
    if mode != "subscribe" or token != settings.whatsapp_verify_token:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Invalid verification token"
        )
    return challenge


@router.post("")
async def receive_webhook(request: Request) -> Response:
    body = await request.body()
    signature = request.headers.get("X-Hub-Signature-256", "")

    expected = (
        "sha256="
        + hmac.new(
            settings.whatsapp_app_secret.encode(), body, hashlib.sha256
        ).hexdigest()
    )

    if not hmac.compare_digest(signature, expected):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Invalid webhook signature"
        )

    payload = WhatsAppWebhook.model_validate(body)

    for entry in payload.entry:
        for change in entry.changes:
            for message in change.value.messages:
                if message.type == "text" and message.text:
                    logger.info(
                        "WhatsApp text message received: %s",
                        message.id,
                    )

    return Response(status_code=status.HTTP_200_OK)
