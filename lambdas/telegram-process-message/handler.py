import json
import os
from functools import lru_cache
from urllib.request import Request, urlopen

import boto3


@lru_cache(maxsize=1)
def get_channel_api_key() -> str:
    client = boto3.client("secretsmanager")

    result = client.get_secret_value(
        SecretId=os.environ["SECRET_ID"]
    )

    return json.loads(result["SecretString"])["CHANNEL_API_KEY"]


def process_message(payload: dict) -> dict:
    request = Request(
        url=f'{os.environ["API_URL"]}/channel-messages',
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "X-Channel-API-Key": get_channel_api_key(),
        },
        method="POST",
    )

    with urlopen(request, timeout=120) as response:
        return json.load(response)

def publish_response(payload: dict, response: dict) -> None:
    client = boto3.client("sqs")

    client.send_message(
        QueueUrl=os.environ["OUTBOUND_QUEUE_URL"],
        MessageBody=json.dumps({
            "external_chat_id": payload["external_chat_id"],
            "response": response["response"],
        }),
        MessageGroupId=payload["external_chat_id"],
        MessageDeduplicationId=payload["external_message_id"],
    )

def lambda_handler(event, _):
    for record in event["Records"]:
        payload = json.loads(record["body"])

        response = process_message(payload)

        publish_response(payload, response)    