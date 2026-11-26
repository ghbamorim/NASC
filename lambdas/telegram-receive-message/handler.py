import base64
import hmac
import json
import os
from functools import lru_cache

import boto3


@lru_cache(maxsize=1)
def get_webhook_secret() -> str:
    client = boto3.client("secretsmanager")
    result = client.get_secret_value(SecretId=os.environ["SECRET_ID"])
    return json.loads(result["SecretString"])["TELEGRAM_WEBHOOK_SECRET"]


def publish_message(payload: dict) -> None:
    client = boto3.client("sqs")

    client.send_message(
        QueueUrl=os.environ["INBOUND_QUEUE_URL"],
        MessageBody=json.dumps(payload),
        MessageGroupId=payload["external_chat_id"],
        MessageDeduplicationId=payload["external_message_id"],
    )


def lambda_handler(event, context):
    headers = {
        key.lower(): value for key, value in (event.get("headers") or {}).items()
    }

    token = headers.get("x-telegram-bot-api-secret-token", "")

    if not hmac.compare_digest(
        token.encode("utf-8"),
        get_webhook_secret().encode("utf-8"),
    ):
        return {"statusCode": 401}

    try:
        body = event.get("body") or ""

        if event.get("isBase64Encoded"):
            body = base64.b64decode(body)

        update = json.loads(body)

        if not isinstance(update, dict):
            return {"statusCode": 400}

        message = update.get("message")

        if not message:
            return {"statusCode": 200}

        chat = message["chat"]

        if chat["type"] != "private":
            return {"statusCode": 200}

        sender = message.get("from")

        if not sender or sender.get("is_bot"):
            return {"statusCode": 200}

        payload = {
            "channel": "telegram",
            "external_user_id": str(sender["id"]),
            "external_chat_id": str(chat["id"]),
            "external_message_id": str(update["update_id"]),
            "message_date": message["date"],
        }

        if message.get("text"):
            payload["message_type"] = "text"
            payload["message"] = message["text"]
        elif message.get("voice"):
            voice = message["voice"]

            payload["message_type"] = "voice"
            payload["voice"] = {
                "file_id": voice["file_id"],
                "duration": voice["duration"],
            }

            for field in ("mime_type", "file_size"):
                if field in voice:
                    payload["voice"][field] = voice[field]

        else:
            return {"statusCode": 200}

    except ValueError, KeyError, TypeError, AttributeError:
        return {"statusCode": 400}

    publish_message(payload)

    return {"statusCode": 200}
