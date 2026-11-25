from uuid import UUID, uuid4

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class ChannelUser(Base):
    __tablename__ = "channel_users"

    __table_args__ = (
        UniqueConstraint(
            "user_id",
            "channel",
            name="uq_channel_users_user_channel",
        ),
        UniqueConstraint(
            "channel",
            "external_user_id",
            name="uq_channel_users_external_user",
        ),
    )

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id"))
    channel: Mapped[str] = mapped_column(String(30))
    external_user_id: Mapped[str] = mapped_column(String(255))
