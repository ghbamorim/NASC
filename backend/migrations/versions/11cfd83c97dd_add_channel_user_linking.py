"""add channel user linking

Revision ID: 11cfd83c97dd
Revises: 9dc2dc321126
Create Date: 2026-11-25 15:15:55.619679

"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "11cfd83c97dd"
down_revision: str | Sequence[str] | None = "9dc2dc321126"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Upgrade schema."""

    op.create_table(
        "channel_link_tokens",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("channel", sa.String(length=30), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token_hash"),
    )

    op.create_table(
        "channel_users",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("user_id", sa.Uuid(), nullable=False),
        sa.Column("channel", sa.String(length=30), nullable=False),
        sa.Column("external_user_id", sa.String(length=255), nullable=False),
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
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "channel",
            "external_user_id",
            name="uq_channel_users_external_user",
        ),
        sa.UniqueConstraint(
            "user_id",
            "channel",
            name="uq_channel_users_user_channel",
        ),
    )

    op.add_column(
        "conversations",
        sa.Column("user_id", sa.Uuid(), nullable=True),
    )

    op.create_index(
        op.f("ix_conversations_user_id"),
        "conversations",
        ["user_id"],
        unique=False,
    )

    op.create_foreign_key(
        "fk_conversations_user_id",
        "conversations",
        "users",
        ["user_id"],
        ["id"],
    )

    # Remove legacy mappings without deleting conversations or messages.
    op.execute("DELETE FROM channel_conversations")

    op.drop_constraint(
        "channel_conversations_pkey",
        "channel_conversations",
        type_="primary",
    )

    op.drop_column("channel_conversations", "channel")

    op.add_column(
        "channel_conversations",
        sa.Column("channel_user_id", sa.Uuid(), nullable=False),
    )

    op.create_primary_key(
        "channel_conversations_pkey",
        "channel_conversations",
        ["channel_user_id", "external_chat_id"],
    )

    op.create_foreign_key(
        "fk_channel_conversations_channel_user_id",
        "channel_conversations",
        "channel_users",
        ["channel_user_id"],
        ["id"],
    )


def downgrade() -> None:
    """Downgrade schema."""

    op.execute("DELETE FROM channel_conversations")

    op.drop_constraint(
        "fk_channel_conversations_channel_user_id",
        "channel_conversations",
        type_="foreignkey",
    )

    op.drop_constraint(
        "channel_conversations_pkey",
        "channel_conversations",
        type_="primary",
    )

    op.drop_column("channel_conversations", "channel_user_id")

    op.add_column(
        "channel_conversations",
        sa.Column("channel", sa.String(length=30), nullable=False),
    )

    op.create_primary_key(
        "channel_conversations_pkey",
        "channel_conversations",
        ["channel", "external_chat_id"],
    )

    op.drop_constraint(
        "fk_conversations_user_id",
        "conversations",
        type_="foreignkey",
    )

    op.drop_index(
        op.f("ix_conversations_user_id"),
        table_name="conversations",
    )

    op.drop_column("conversations", "user_id")

    op.drop_table("channel_users")
    op.drop_table("channel_link_tokens")
