import json
import os
from functools import lru_cache
from urllib.request import Request, urlopen

import boto3


@lru_cache(maxsize=1)
def get_telegram_token() -> str:
    client = boto3.client("secretsmanager")

    result = client.get_secret_value(
        SecretId=os.environ["SECRET_ID"]
    )

    secrets = json.loads(result["SecretString"])

    return secrets["TELEGRAM_BOT_TOKEN"]


def send_message(chat_id: str, message: str) -> None:
    token = get_telegram_token()
    url = f"https://api.telegram.org/bot{token}/sendMessage"

    payload = json.dumps({
        "chat_id": chat_id,
        "text": message,
    }).encode("utf-8")

    request = Request(
        url,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urlopen(request, timeout=10) as response:
        result = json.load(response)

        if not result.get("ok"):
            raise RuntimeError("Failed to send Telegram message")


def lambda_handler(event, context):
    for record in event["Records"]:
        payload = json.loads(record["body"])

        send_message(
            chat_id=payload["external_chat_id"],
            message=payload["response"],
        )