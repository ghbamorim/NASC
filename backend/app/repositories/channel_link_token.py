from datetime import datetime
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.channel_link_token import ChannelLinkToken


class ChannelLinkTokenRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(
        self,
        user_id: UUID,
        channel: str,
        token_hash: str,
        expires_at: datetime,
    ) -> ChannelLinkToken:
        token = ChannelLinkToken(
            user_id=user_id,
            channel=channel,
            token_hash=token_hash,
            expires_at=expires_at,
        )

        self.db.add(token)
        await self.db.flush()

        return token

    async def get(
        self,
        token_id: UUID,
    ) -> ChannelLinkToken | None:
        return await self.db.get(ChannelLinkToken, token_id)

    async def get_by_hash(
        self,
        token_hash: str,
    ) -> ChannelLinkToken | None:
        stmt = select(ChannelLinkToken).where(
            ChannelLinkToken.token_hash == token_hash,
        )

        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def consume(
        self,
        token_hash: str,
        channel: str,
        now: datetime,
    ) -> ChannelLinkToken | None:
        stmt = (
            update(ChannelLinkToken)
            .where(
                ChannelLinkToken.token_hash == token_hash,
                ChannelLinkToken.channel == channel,
                ChannelLinkToken.expires_at > now,
                ChannelLinkToken.used_at.is_(None),
                ChannelLinkToken.revoked_at.is_(None),
            )
            .values(used_at=now)
            .returning(ChannelLinkToken)
        )

        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def revoke_pending(
        self,
        user_id: UUID,
        channel: str,
        now: datetime,
    ) -> None:
        stmt = (
            update(ChannelLinkToken)
            .where(
                ChannelLinkToken.user_id == user_id,
                ChannelLinkToken.channel == channel,
                ChannelLinkToken.used_at.is_(None),
                ChannelLinkToken.revoked_at.is_(None),
            )
            .values(revoked_at=now)
        )

        await self.db.execute(stmt)
