from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class WhatsAppMessageReceipt(Base):
    __tablename__ = "whatsapp_message_receipts"

    message_id: Mapped[str] = mapped_column(String(255), primary_key=True)
