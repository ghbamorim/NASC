from fastapi import FastAPI

from app.routers.chat import router as chat_router
from app.routers.whatsapp import router as whatsapp_router

app = FastAPI(title="NASC API")


@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(chat_router)
app.include_router(whatsapp_router)
