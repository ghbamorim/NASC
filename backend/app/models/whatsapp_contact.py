from uuid import UUID

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class WhatsAppContact(Base):
    __tablename__ = "whatsapp_contacts"

    phone_number: Mapped[str] = mapped_column(String(30), primary_key=True)

    conversation_id: Mapped[UUID] = mapped_column(ForeignKey("conversations.id"))
