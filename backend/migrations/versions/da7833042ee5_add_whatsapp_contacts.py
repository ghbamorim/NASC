"""add whatsapp contacts

Revision ID: da7833042ee5
Revises: d3ff83751dd5
Create Date: 2026-11-12 16:55:43.492670

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "da7833042ee5"
down_revision: str | Sequence[str] | None = "d3ff83751dd5"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""

    op.create_table(
        "whatsapp_contacts",
        sa.Column("phone_number", sa.String(length=30), nullable=False),
        sa.Column("conversation_id", sa.Uuid(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(
            ["conversation_id"],
            ["conversations.id"],
        ),
        sa.PrimaryKeyConstraint("phone_number"),
    )


def downgrade() -> None:
    """Downgrade schema."""

    op.drop_table("whatsapp_contacts")
