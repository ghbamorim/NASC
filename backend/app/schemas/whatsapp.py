from pydantic import BaseModel, Field


class WhatsAppMessage(BaseModel):
    id: str
    from_number: str = Field(alias="from")
    type: str
    text: dict[str, str] | None = None


class WhatsAppValue(BaseModel):
    messages: list[WhatsAppMessage] = Field(default_factory=list)


class WhatsAppChange(BaseModel):
    value: WhatsAppValue


class WhatsAppEntry(BaseModel):
    changes: list[WhatsAppChange]


class WhatsAppWebhook(BaseModel):
    entry: list[WhatsAppEntry] = Field(default_factory=list)
