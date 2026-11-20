import base64
import json
import logging
import os
import secrets
from functools import lru_cache
from http import HTTPStatus

import boto3

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

sqs = boto3.client("sqs")
secrets_manager = boto3.client("secretsmanager")

QUEUE_URL = os.environ["QUEUE_URL"]
WEBHOOK_SECRET_ARN = os.environ["WEBHOOK_SECRET_ARN"]


@lru_cache(maxsize=1)
def get_webhook_secret() -> str:
    result = secrets_manager.get_secret_value(
        SecretId=WEBHOOK_SECRET_ARN,
    )
    return result["SecretString"]


def response(status_code: int, message: str) -> dict:
    return {
        "statusCode": status_code,
        "body": json.dumps({"message": message}),
    }


def lambda_handler(event: dict, _context: object) -> dict:
    headers = {
        key.lower(): value
        for key, value in (event.get("headers") or {}).items()
    }

    received_secret = headers.get(
        "x-telegram-bot-api-secret-token",
        "",
    )

    if not secrets.compare_digest(
        received_secret,
        get_webhook_secret(),
    ):
        return response(HTTPStatus.FORBIDDEN, "Forbidden")

    try:
        body = event.get("body") or "{}"

        if event.get("isBase64Encoded"):
            body = base64.b64decode(body).decode("utf-8")

        update = json.loads(body)

    except (ValueError, UnicodeDecodeError):
        return response(HTTPStatus.BAD_REQUEST, "Invalid JSON")

    telegram_message = update.get("message")

    if not isinstance(telegram_message, dict):
        return response(HTTPStatus.OK, "Ignored update")

    chat = telegram_message.get("chat") or {}
    text = telegram_message.get("text")
    message_id = telegram_message.get("message_id")

    if (
        chat.get("id") is None
        or message_id is None
        or not isinstance(text, str)
        or not text.strip()
    ):
        return response(HTTPStatus.OK, "Ignored message")

    payload = {
        "channel": "telegram",
        "external_chat_id": str(chat["id"]),
        "message": text,
        "message_id": str(message_id),
        "update_id": update.get("update_id"),
    }

    sqs.send_message(
        QueueUrl=QUEUE_URL,
        MessageBody=json.dumps(payload),
    )

    logger.info(
        "Telegram message %s published to SQS",
        message_id,
    )

    return response(HTTPStatus.OK, "Accepted")