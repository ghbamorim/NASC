from fastapi import FastAPI

from app.routers.channel_messages import router as channel_messages_router
from app.routers.chat import router as chat_router

app = FastAPI(title="NASC API")


@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(chat_router)
app.include_router(channel_messages_router)
