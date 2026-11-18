from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories.channel_conversation import (
    ChannelConversationRepository,
)
from app.services.chat import ChatService


class ChannelMessageService:
    def __init__(
        self,
        db: AsyncSession,
        channel_conversation_repository: ChannelConversationRepository | None = None,
    ) -> None:
        self.db = db
        self.channel_conversation_repository = (
            channel_conversation_repository or ChannelConversationRepository(db)
        )
        self.chat_service = ChatService(db)

    async def process(
        self,
        channel: str,
        external_chat_id: str,
        message: str,
    ) -> tuple[UUID, str]:
        conversation_id = (
            await self.channel_conversation_repository.get_conversation_id(
                channel=channel,
                external_chat_id=external_chat_id,
            )
        )

        conversation_id, response = await self.chat_service.chat(
            message=message,
            conversation_id=conversation_id,
        )

        if conversation_id is not None:
            existing_id = (
                await self.channel_conversation_repository.get_conversation_id(
                    channel=channel,
                    external_chat_id=external_chat_id,
                )
            )

            if existing_id is None:
                await self.channel_conversation_repository.create(
                    channel=channel,
                    external_chat_id=external_chat_id,
                    conversation_id=conversation_id,
                )

        return conversation_id, response
