from uuid import UUID

from pydantic_ai.messages import (
    ModelMessage,
    ModelRequest,
    ModelResponse,
    TextPart,
    UserPromptPart,
)
from sqlalchemy.ext.asyncio import AsyncSession

from app.agents.nasc import nasc_agent
from app.repositories.conversation import ConversationRepository


class ChatService:
    def __init__(
        self,
        db: AsyncSession,
        conversation_repository: ConversationRepository | None = None,
    ) -> None:
        self.db = db
        self.repository = conversation_repository or ConversationRepository(db)

    async def chat(
        self, message: str, conversation_id: UUID | None = None
    ) -> tuple[UUID, str]:
        history: list[ModelMessage] = []

        if conversation_id is None:
            conversation = await self.repository.create()
        else:
            conversation = await self.repository.get(conversation_id)

            if conversation is None:
                raise ValueError("Conversation not found")

            for item in conversation.messages:
                if item.role == "user":
                    history.append(
                        ModelRequest(parts=[UserPromptPart(content=item.content)])
                    )
                elif item.role == "assistant":
                    history.append(
                        ModelResponse(parts=[TextPart(content=item.content)])
                    )

        result = await nasc_agent.run(message, message_history=history)

        await self.repository.add_message(conversation.id, "user", message)
        await self.repository.add_message(conversation.id, "assistant", result.output)

        return conversation.id, result.output
