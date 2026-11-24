from uuid import UUID

from pydantic import BaseModel


class ChannelMessageResponse(BaseModel):
    conversation_id: UUID
    response: str
