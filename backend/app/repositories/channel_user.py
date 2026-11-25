from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.channel_user import ChannelUser


class ChannelUserRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(
        self,
        user_id: UUID,
        channel: str,
        external_user_id: str,
    ) -> ChannelUser:
        channel_user = ChannelUser(
            user_id=user_id,
            channel=channel,
            external_user_id=external_user_id,
        )

        self.db.add(channel_user)
        await self.db.flush()

        return channel_user

    async def get(self, channel_user_id: UUID) -> ChannelUser | None:
        return await self.db.get(ChannelUser, channel_user_id)

    async def get_by_user(
        self,
        user_id: UUID,
        channel: str,
    ) -> ChannelUser | None:
        stmt = select(ChannelUser).where(
            ChannelUser.user_id == user_id,
            ChannelUser.channel == channel,
        )

        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def get_by_external_user(
        self,
        channel: str,
        external_user_id: str,
    ) -> ChannelUser | None:
        stmt = select(ChannelUser).where(
            ChannelUser.channel == channel,
            ChannelUser.external_user_id == external_user_id,
        )

        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def list_by_user(
        self,
        user_id: UUID,
    ) -> list[ChannelUser]:
        stmt = select(ChannelUser).where(
            ChannelUser.user_id == user_id,
        )

        result = await self.db.execute(stmt)
        return list(result.scalars().all())

    async def delete(self, channel_user: ChannelUser) -> None:
        await self.db.delete(channel_user)
        await self.db.flush()
