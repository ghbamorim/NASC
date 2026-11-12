"""add whatsapp message receipts

Revision ID: d3ff83751dd5
Revises: 5441b839021b
Create Date: 2026-11-12 16:39:25.994400

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "d3ff83751dd5"
down_revision: str | Sequence[str] | None = "5441b839021b"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table(
        "whatsapp_message_receipts",
        sa.Column("message_id", sa.String(length=255), nullable=False),
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
        sa.PrimaryKeyConstraint("message_id"),
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_table("whatsapp_message_receipts")
