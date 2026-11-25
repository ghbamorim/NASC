from uuid import UUID

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class ChannelConversation(Base):
    __tablename__ = "channel_conversations"

    channel_user_id: Mapped[UUID] = mapped_column(
        ForeignKey("channel_users.id"),
        primary_key=True,
    )
    external_chat_id: Mapped[str] = mapped_column(
        String(255),
        primary_key=True,
    )
    conversation_id: Mapped[UUID] = mapped_column(
        ForeignKey("conversations.id"),
    )
