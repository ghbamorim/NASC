from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from app.core.exceptions import NotFoundError
from app.routers.auth import router as auth_router
from app.routers.channel_messages import router as channel_messages_router
from app.routers.channel_user import router as channel_user_router
from app.routers.chat import router as chat_router
from app.routers.user import router as user_router

app = FastAPI(title="NASC API")


@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(chat_router)
app.include_router(channel_messages_router)
app.include_router(user_router)
app.include_router(auth_router)
app.include_router(channel_user_router)


@app.exception_handler(NotFoundError)
async def not_found_handler(
    _: Request,
    exc: NotFoundError,
) -> JSONResponse:
    return JSONResponse(
        status_code=404,
        content={"detail": str(exc)},
    )


@app.exception_handler(RequestValidationError)
async def validation_error_handler(
    _: Request,
    exc: RequestValidationError,
) -> JSONResponse:
    return JSONResponse(
        status_code=422,
        content={
            "detail": [
                {
                    "loc": error["loc"],
                    "msg": error["msg"],
                    "type": error["type"],
                }
                for error in exc.errors()
            ]
        },
    )
