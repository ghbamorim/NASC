from typing import TYPE_CHECKING
from uuid import UUID, uuid4

from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.message import Message


class Conversation(Base):
    __tablename__ = "conversations"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    messages: Mapped[list["Message"]] = relationship(cascade="all, delete-orphan")
