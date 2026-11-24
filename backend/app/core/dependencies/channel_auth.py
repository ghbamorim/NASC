from secrets import compare_digest
from typing import Annotated

from fastapi import Depends, HTTPException
from fastapi.security import APIKeyHeader

from app.core.settings import settings

api_key_header = APIKeyHeader(
    name="X-Channel-API-Key",
    auto_error=False,
)


async def verify_channel_api_key(
    api_key: Annotated[str | None, Depends(api_key_header)],
) -> None:
    if api_key is None or not compare_digest(
        api_key,
        settings.channel_api_key.get_secret_value(),
    ):
        raise HTTPException(
            status_code=401,
            detail="Invalid channel API key",
        )
