from uuid import UUID

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.core.dependencies.database import DBSession
from app.services.chat import ChatService

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatRequest(BaseModel):
    message: str
    conversation_id: UUID | None = None


class ChatResponse(BaseModel):
    conversation_id: UUID
    response: str


@router.post("", response_model=ChatResponse)
async def chat(request: ChatRequest, db: DBSession) -> ChatResponse:
    service = ChatService(db)

    try:
        conversation_id, response = await service.chat(
            message=request.message,
            conversation_id=request.conversation_id,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    return ChatResponse(
        conversation_id=conversation_id,
        response=response,
    )
