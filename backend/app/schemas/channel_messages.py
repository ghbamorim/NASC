from typing import Literal, Self
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class VoiceMetadata(BaseModel):
    file_id: str = Field(min_length=1)
    duration: int = Field(ge=0, strict=True)
    mime_type: str | None = None
    file_size: int | None = Field(default=None, gt=0, strict=True)


class ChannelMessageRequest(BaseModel):
    channel: Literal["telegram"]
    external_user_id: str = Field(min_length=1, max_length=255)
    external_chat_id: str = Field(min_length=1, max_length=255)
    external_message_id: str = Field(min_length=1, max_length=255)
    message_date: int = Field(gt=0, strict=True)

    message_type: Literal["text", "voice"] = "text"
    message: str | None = Field(default=None, min_length=1)
    voice: VoiceMetadata | None = None

    @model_validator(mode="after")
    def validate_message_type(self) -> Self:
        if self.message_type == "text" and (
            self.message is None or "voice" in self.model_fields_set
        ):
            raise ValueError("Text messages require message and forbid voice.")
        elif self.message_type == "voice" and (
            self.voice is None or "message" in self.model_fields_set
        ):
            raise ValueError("Voice messages require voice and forbid message")
        return self


class ChannelMessageResponse(BaseModel):
    conversation_id: UUID | None = None
    message_type: Literal["text", "voice"] = "text"
    response_type: Literal["text"] = "text"
    response: str
