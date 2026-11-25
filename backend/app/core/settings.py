from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    database_url: str
    database_pool_pre_ping: bool = False
    database_echo: bool = False
    database_pool_size: int = 5
    database_pool_max_overflow: int = 2
    database_echo_pool: None | bool | Literal["debug"] = False

    jwt_secret_key: SecretStr
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 60 * 24 * 7

    auth_cookie_name: str = "access_token"
    auth_cookie_secure: bool = False
    auth_cookie_samesite: Literal["lax", "strict", "none"] | None = "lax"

    telegram_bot_token: str
    channel_api_key: SecretStr

    gemini_api_key: str
    gemini_model: str
    gemini_fallback_models: list[str]

    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore


settings = get_settings()
