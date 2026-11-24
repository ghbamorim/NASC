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
        external_message_id: str,
        message: str,
    ) -> tuple[UUID, str]:
        await self.channel_conversation_repository.lock(
            channel=channel,
            external_chat_id=external_chat_id,
        )

        conversation_id = (
            await self.channel_conversation_repository.get_conversation_id(
                channel=channel,
                external_chat_id=external_chat_id,
            )
        )

        is_new_conversation = conversation_id is None

        conversation_id, response = await self.chat_service.chat(
            message=message,
            conversation_id=conversation_id,
            external_message_id=external_message_id,
        )

        if is_new_conversation:
            await self.channel_conversation_repository.create(
                channel=channel,
                external_chat_id=external_chat_id,
                conversation_id=conversation_id,
            )

        return conversation_id, response
