import json
import logging
import os
import urllib.error
import urllib.request

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

FASTAPI_URL = os.environ["FASTAPI_URL"].rstrip("/")


def process_message(payload: dict) -> None:
    body = json.dumps(
        {
            "channel": payload["channel"],
            "external_chat_id": payload["external_chat_id"],
            "message": payload["message"],
        }
    ).encode("utf-8")

    request = urllib.request.Request(
        url=f"{FASTAPI_URL}/channel-messages",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    with urllib.request.urlopen(request, timeout=120) as response:
        result = json.load(response)

    logger.info(
        "Message %s processed successfully; conversation_id=%s",
        payload.get("message_id"),
        result["conversation_id"],
    )


def lambda_handler(event: dict, _context: object) -> dict:
    failures = []

    for record in event["Records"]:
        try:
            payload = json.loads(record["body"])
            process_message(payload)

        except (
            ValueError,
            KeyError,
            urllib.error.URLError,
            TimeoutError,
        ):
            logger.exception(
                "Failed to process SQS message %s",
                record["messageId"],
            )

            failures.append(
                {"itemIdentifier": record["messageId"]}
            )

    return {"batchItemFailures": failures}