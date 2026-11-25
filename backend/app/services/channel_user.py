from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.channel_user import ChannelUser
from app.repositories.channel_conversation import ChannelConversationRepository
from app.repositories.channel_user import ChannelUserRepository
from app.services.channel_link_token import ChannelLinkTokenService


class ChannelUserService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db
        self.channel_user_repository = ChannelUserRepository(db)
        self.channel_conversation_repository = ChannelConversationRepository(db)
        self.channel_link_token_service = ChannelLinkTokenService(db)

    async def link(
        self,
        channel: str,
        external_user_id: str,
        token: str,
    ) -> ChannelUser:
        await self.channel_conversation_repository.lock(
            channel=channel,
            external_chat_id=external_user_id,
        )

        async with self.db.begin_nested():
            existing_link = await self.channel_user_repository.get_by_external_user(
                channel=channel,
                external_user_id=external_user_id,
            )

            if existing_link is not None:
                raise ValueError("External account already linked")

            link_token = await self.channel_link_token_service.consume(
                token=token,
                channel=channel,
            )

            if link_token is None:
                raise ValueError("Invalid or expired link token")

            existing_link = await self.channel_user_repository.get_by_user(
                user_id=link_token.user_id,
                channel=channel,
            )

            if existing_link is not None:
                raise ValueError("User already linked to this channel")

            return await self.channel_user_repository.create(
                user_id=link_token.user_id,
                channel=channel,
                external_user_id=external_user_id,
            )

    async def get_by_user(
        self,
        user_id: UUID,
        channel: str,
    ) -> ChannelUser | None:
        return await self.channel_user_repository.get_by_user(
            user_id=user_id,
            channel=channel,
        )

    async def get_by_external_user(
        self,
        channel: str,
        external_user_id: str,
    ) -> ChannelUser | None:
        return await self.channel_user_repository.get_by_external_user(
            channel=channel,
            external_user_id=external_user_id,
        )

    async def list_by_user(
        self,
        user_id: UUID,
    ) -> list[ChannelUser]:
        return await self.channel_user_repository.list_by_user(
            user_id=user_id,
        )

    async def unlink(
        self,
        user_id: UUID,
        channel: str,
    ) -> None:
        channel_user = await self.channel_user_repository.get_by_user(
            user_id=user_id,
            channel=channel,
        )

        if channel_user is None:
            raise ValueError("User is not linked to this channel")

        channel_user_id = channel_user.id

        await self.channel_conversation_repository.lock(
            channel=channel,
            external_chat_id=channel_user.external_user_id,
        )

        await self.channel_link_token_service.lock(
            user_id=user_id,
            channel=channel,
        )

        channel_user = await self.channel_user_repository.get_by_user(
            user_id=user_id,
            channel=channel,
        )

        if channel_user is None or channel_user.id != channel_user_id:
            raise ValueError("Channel link has changed")

        await self.channel_link_token_service.revoke(
            user_id=user_id,
            channel=channel,
        )

        await self.channel_conversation_repository.delete_by_channel_user(
            channel_user_id=channel_user.id,
        )

        await self.channel_user_repository.delete(channel_user)
