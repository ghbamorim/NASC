from fastapi import APIRouter
from pydantic import BaseModel

from app.agents.nasc import nasc_agent

router = APIRouter(prefix="/chat", tags=["chat"])


class ChatRequest(BaseModel):
    message: str


class ChatResponse(BaseModel):
    response: str


@router.post("", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    result = await nasc_agent.run(request.message)
    return ChatResponse(response=result.output)
