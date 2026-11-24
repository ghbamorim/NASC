from fastapi import APIRouter, Depends
from pydantic import Field

from app.core.dependencies.channel_auth import verify_channel_api_key
from app.core.dependencies.database import DbSession
from app.schemas.channel_messages import ChannelMessageResponse
from app.services.channel_message import ChannelMessageService

router = APIRouter(prefix="/channel-messages", tags=["Channels"])


@router.post(
    "",
    response_model=ChannelMessageResponse,
    dependencies=[Depends(verify_channel_api_key)],
)
async def process_channel_message(
    db: DbSession,
    channel: str = Field(min_length=1, max_length=30),
    external_chat_id: str = Field(min_length=1, max_length=255),
    external_message_id: str = Field(min_length=1, max_length=255),
    message: str = Field(min_length=1),
) -> ChannelMessageResponse:
    service = ChannelMessageService(db)

    conversation_id, response = await service.process(
        channel=channel,
        external_chat_id=external_chat_id,
        external_message_id=external_message_id,
        message=message,
    )

    return ChannelMessageResponse(
        conversation_id=conversation_id,
        response=response,
    )
