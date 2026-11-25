import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.channel_link_token import ChannelLinkToken
from app.models.user import User
from app.repositories.channel_link_token import ChannelLinkTokenRepository
from app.repositories.channel_user import ChannelUserRepository


class ChannelLinkTokenService:
    def __init__(
        self,
        db: AsyncSession,
        expire_minutes: int = 10,
    ) -> None:
        self.db = db
        self.expire_minutes = expire_minutes
        self.token_repository = ChannelLinkTokenRepository(db)
        self.channel_user_repository = ChannelUserRepository(db)

    @staticmethod
    def hash_token(token: str) -> str:
        return hashlib.sha256(token.encode("utf-8")).hexdigest()

    async def lock(
        self,
        user_id: UUID,
        channel: str,
    ) -> None:
        key = f"channel-link:{user_id}:{channel}"

        await self.db.execute(
            select(func.pg_advisory_xact_lock(func.hashtextextended(key, 0)))
        )

    async def generate(
        self,
        user_id: UUID,
        channel: str,
    ) -> str:
        await self.lock(user_id, channel)

        user = await self.db.get(User, user_id)

        if user is None:
            raise ValueError("User not found")

        if not user.is_active:
            raise ValueError("User is inactive")

        channel_user = await self.channel_user_repository.get_by_user(
            user_id=user_id,
            channel=channel,
        )

        if channel_user is not None:
            raise ValueError("User already linked to this channel")

        now = datetime.now(UTC)

        await self.token_repository.revoke_pending(
            user_id=user_id,
            channel=channel,
            now=now,
        )

        token = secrets.token_urlsafe(32)

        await self.token_repository.create(
            user_id=user_id,
            channel=channel,
            token_hash=self.hash_token(token),
            expires_at=now + timedelta(minutes=self.expire_minutes),
        )

        return token

    async def consume(
        self,
        token: str,
        channel: str,
    ) -> ChannelLinkToken | None:
        token_hash = self.hash_token(token)

        link_token = await self.token_repository.get_by_hash(
            token_hash=token_hash,
        )

        if link_token is None or link_token.channel != channel:
            return None

        await self.lock(link_token.user_id, channel)

        user = await self.db.get(User, link_token.user_id)

        if user is None or not user.is_active:
            return None

        return await self.token_repository.consume(
            token_hash=token_hash,
            channel=channel,
            now=datetime.now(UTC),
        )

    async def revoke(
        self,
        user_id: UUID,
        channel: str,
    ) -> None:
        await self.lock(user_id, channel)

        await self.token_repository.revoke_pending(
            user_id=user_id,
            channel=channel,
            now=datetime.now(UTC),
        )
