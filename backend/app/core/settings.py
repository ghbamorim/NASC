from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, SecretStr
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
    telegram_bot_username: str
    channel_link_token_expire_minutes: int = 10
    telegram_voice_max_size_bytes: int = Field(default=5 * 1024 * 1024, gt=0)
    telegram_voice_max_duration_seconds: int = Field(default=300, gt=0)
    telegram_voice_download_timeout_seconds: int = Field(default=30, gt=0)
    channel_message_timeout_seconds: int = Field(default=420, gt=0)

    gemini_api_key: str
    gemini_chat_models: list[str] = Field(min_length=1)
    gemini_chat_model_timeout_seconds: int = Field(default=60, gt=0)
    gemini_chat_timeout_seconds: int = Field(default=180, gt=0)

    gemini_transcription_models: list[str] = Field(min_length=1)
    gemini_transcription_model_timeout_seconds: int = Field(default=60, gt=0)
    gemini_transcription_timeout_seconds: int = Field(default=180, gt=0)

    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()  # type: ignore


settings = get_settings()
