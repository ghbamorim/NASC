from pathlib import Path
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    database_url: str
    database_pool_pre_ping: bool = False
    database_echo: bool = False
    database_pool_size: int = 5
    database_pool_max_overflow: int = 2
    database_echo_pool: None | bool | Literal["debug"] = False

    gemini_api_key: str
    gemini_model: str

    model_config = SettingsConfigDict(
        env_file=BACKEND_DIR / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


settings = Settings()  # type: ignore
