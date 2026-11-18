"""add message sequence

Revision ID: 5441b839021b
Revises: 6e42dd79e090
Create Date: 2026-11-12 14:59:26.351760

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "5441b839021b"
down_revision: str | Sequence[str] | None = "6e42dd79e090"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column("messages", sa.Column("sequence", sa.Integer(), nullable=False))
    op.create_unique_constraint(
        "uq_messages_conversation_sequence", "messages", ["conversation_id", "sequence"]
    )


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_constraint("uq_messages_conversation_sequence", "messages", type_="unique")
    op.drop_column("messages", "sequence")
