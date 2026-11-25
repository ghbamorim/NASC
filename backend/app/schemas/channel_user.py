from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class ChannelUserResponse(BaseModel):
    id: UUID
    user_id: UUID
    channel: str
    external_user_id: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ChannelLinkResponse(BaseModel):
    channel: str
    link: str
    expires_in_seconds: int
