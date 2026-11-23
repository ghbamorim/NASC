import json
import logging
import os
import urllib.error
import urllib.request
from functools import lru_cache

import boto3

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

secrets_manager = boto3.client("secretsmanager")

TELEGRAM_BOT_TOKEN_SECRET_ARN = os.environ[
    "TELEGRAM_BOT_TOKEN_SECRET_ARN"
]


@lru_cache(maxsize=1)
def get_bot_token() -> str:
    result = secrets_manager.get_secret_value(
        SecretId=TELEGRAM_BOT_TOKEN_SECRET_ARN
    )
    return result["SecretString"]


def send_telegram_message(chat_id: str, message: str) -> None:
    token = get_bot_token()

    payload = json.dumps(
        {
            "chat_id": chat_id,
            "text": message,
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        url=f"https://api.telegram.org/bot{token}/sendMessage",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=20) as response:
        result = json.load(response)

    if not result.get("ok"):
        raise RuntimeError("Telegram rejected the message")


def lambda_handler(event: dict, _context: object) -> dict:
    failures = []

    for record in event["Records"]:
        try:
            payload = json.loads(record["body"])

            send_telegram_message(
                chat_id=payload["external_chat_id"],
                message=payload["response"],
            )

            logger.info(
                "Telegram response sent for chat %s",
                payload["external_chat_id"],
            )

        except Exception:
            logger.exception(
                "Failed to send SQS message %s",
                record["messageId"],
            )

            failures.append(
                {"itemIdentifier": record["messageId"]}
            )

    return {"batchItemFailures": failures}