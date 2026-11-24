"""add external message id

Revision ID: 9dc2dc321126
Revises: f23d6189f38f
Create Date: 2026-11-24 15:23:58.188401

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "9dc2dc321126"
down_revision: str | Sequence[str] | None = "f23d6189f38f"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column(
        "messages",
        sa.Column("external_message_id", sa.String(length=255), nullable=True),
    )
    op.create_unique_constraint(
        "uq_messages_conversation_external_id",
        "messages",
        ["conversation_id", "external_message_id"],
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint(
        "uq_messages_conversation_external_id", "messages", type_="unique"
    )
    op.drop_column("messages", "external_message_id")
