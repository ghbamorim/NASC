import hmac
import json
import logging
import os

import httpx

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def lambda_handler(event: dict, context: object) -> dict:
    headers = {
        key.lower(): value for key, value in (event.get("headers") or {}).items()
    }

    expected_secret = os.environ["TELEGRAM_WEBHOOK_SECRET"]
    received_secret = headers.get("x-telegram-bot-api-secret-token", "")

    if not hmac.compare_digest(received_secret, expected_secret):
        return {
            "statusCode": 403,
            "body": json.dumps({"error": "Forbidden"}),
        }

    body = event.get("body") or "{}"

    if event.get("isBase64Encoded"):
        raise ValueError("Base64 payload is not supported yet")

    update = json.loads(body)

    message = update.get("message", {})
    chat_id = message.get("chat", {}).get("id")
    text = message.get("text")

    if chat_id is None or not text:
        return {"statusCode": 200, "body": json.dumps({"ok": True})}

    logger.info("Received Telegram message from chat %s", chat_id)

    result = send_to_nasc(chat_id, text)
    send_to_telegram(chat_id, result["response"])

    return {"statusCode": 200, "body": json.dumps({"ok": True})}


def send_to_nasc(
    chat_id: int,
    message: str,
) -> dict:
    api_url = os.environ["NASC_API_URL"]

    response = httpx.post(
        f"{api_url}/channel-messages",
        json={
            "channel": "telegram",
            "external_chat_id": str(chat_id),
            "message": message,
        },
        timeout=60.0,
    )

    response.raise_for_status()
    return response.json()


def send_to_telegram(chat_id: int, message: str) -> None:
    bot_token = os.environ["TELEGRAM_BOT_TOKEN"]

    response = httpx.post(
        f"https://api.telegram.org/bot{bot_token}/sendMessage",
        json={
            "chat_id": chat_id,
            "text": message,
        },
        timeout=15.0,
    )

    response.raise_for_status()
