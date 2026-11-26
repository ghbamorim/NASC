import asyncio

from fastapi import APIRouter, Depends

from app.core.dependencies.channel_auth import verify_channel_api_key
from app.core.dependencies.database import DbSession
from app.core.settings import settings
from app.schemas.channel_messages import (
    ChannelMessageRequest,
    ChannelMessageResponse,
)
from app.services.channel_message import ChannelMessageService

router = APIRouter(prefix="/channel-messages", tags=["Channels"])


@router.post(
    "",
    response_model=ChannelMessageResponse,
    dependencies=[Depends(verify_channel_api_key)],
)
async def process_channel_message(
    db: DbSession,
    data: ChannelMessageRequest,
) -> ChannelMessageResponse:
    service = ChannelMessageService(db)
    async with asyncio.timeout(settings.channel_message_timeout_seconds):
        conversation_id, response = await service.process(
            channel=data.channel,
            external_user_id=data.external_user_id,
            external_chat_id=data.external_chat_id,
            external_message_id=data.external_message_id,
            message_date=data.message_date,
            message_type=data.message_type,
            message=data.message,
            voice=data.voice,
        )

    return ChannelMessageResponse(
        conversation_id=conversation_id,
        message_type=data.message_type,
        response_type=service.get_response_type(data.message_type),
        response=response,
    )
