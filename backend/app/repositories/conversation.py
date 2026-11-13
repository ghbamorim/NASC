from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.conversation import Conversation
from app.models.message import Message, MessageRole


class ConversationRepository:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def create(self) -> Conversation:
        conversation = Conversation()
        self.db.add(conversation)
        await self.db.flush()
        return conversation

    async def get(self, conversation_id: UUID) -> Conversation | None:
        stmt = (
            select(Conversation)
            .options(selectinload(Conversation.messages))
            .where(Conversation.id == conversation_id)
        )
        return await self.db.scalar(stmt)

    async def add_message(
        self, conversation_id: UUID, role: MessageRole, content: str
    ) -> Message:
        stmt = (
            select(Conversation)
            .where(Conversation.id == conversation_id)
            .with_for_update()
        )

        conversation = await self.db.scalar(stmt)

        if conversation is None:
            raise ValueError("Conversation not found")

        next_sequence_stmt = select(
            func.coalesce(
                func.max(Message.sequence),
                0,
            )
            + 1
        ).where(Message.conversation_id == conversation_id)

        next_sequence = await self.db.scalar(next_sequence_stmt)

        message = Message(
            conversation_id=conversation_id,
            role=role,
            content=content,
            sequence=next_sequence,
        )
        self.db.add(message)
        await self.db.flush()
        return message
