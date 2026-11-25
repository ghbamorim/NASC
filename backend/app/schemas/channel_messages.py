from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


class ChannelMessageRequest(BaseModel):
    channel: Literal["telegram"]
    external_user_id: str = Field(min_length=1, max_length=255)
    external_chat_id: str = Field(min_length=1, max_length=255)
    external_message_id: str = Field(min_length=1, max_length=255)
    message_date: int = Field(gt=0, strict=True)
    message: str = Field(min_length=1)


class ChannelMessageResponse(BaseModel):
    conversation_id: UUID | None = None
    response: str
