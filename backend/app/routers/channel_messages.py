from uuid import UUID

from fastapi import APIRouter
from pydantic import BaseModel, Field

from app.core.dependencies.database import DbSession
from app.services.channel_message import ChannelMessageService

router = APIRouter(prefix="/channel-messages", tags=["Channels"])


class ChannelMessageRequest(BaseModel):
    channel: str = Field(min_length=1, max_length=30)
    external_chat_id: str = Field(min_length=1, max_length=255)
    message: str = Field(min_length=1)


class ChannelMessageResponse(BaseModel):
    conversation_id: UUID
    response: str


@router.post("", response_model=ChannelMessageResponse)
async def process_channel_message(
    request: ChannelMessageRequest,
    db: DbSession,
) -> ChannelMessageResponse:
    service = ChannelMessageService(db)

    conversation_id, response = await service.process(
        channel=request.channel,
        external_chat_id=request.external_chat_id,
        message=request.message,
    )

    await db.commit()

    return ChannelMessageResponse(
        conversation_id=conversation_id,
        response=response,
    )
