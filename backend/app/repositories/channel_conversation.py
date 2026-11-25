from uuid import UUID

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.channel_conversation import ChannelConversation


class ChannelConversationRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def get_conversation_id(
        self,
        channel_user_id: UUID,
        external_chat_id: str,
    ) -> UUID | None:
        statement = select(ChannelConversation.conversation_id).where(
            ChannelConversation.channel_user_id == channel_user_id,
            ChannelConversation.external_chat_id == external_chat_id,
        )

        return await self.db.scalar(statement)

    async def create(
        self,
        channel_user_id: UUID,
        external_chat_id: str,
        conversation_id: UUID,
    ) -> ChannelConversation:
        mapping = ChannelConversation(
            channel_user_id=channel_user_id,
            external_chat_id=external_chat_id,
            conversation_id=conversation_id,
        )

        self.db.add(mapping)
        await self.db.flush()

        return mapping

    async def delete_by_channel_user(
        self,
        channel_user_id: UUID,
    ) -> None:
        statement = delete(ChannelConversation).where(
            ChannelConversation.channel_user_id == channel_user_id,
        )

        await self.db.execute(statement)

    async def lock(
        self,
        channel: str,
        external_chat_id: str,
    ) -> None:
        key = f"{channel}:{external_chat_id}"

        await self.db.execute(
            select(func.pg_advisory_xact_lock(func.hashtextextended(key, 0)))
        )
