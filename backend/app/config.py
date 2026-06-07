from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    # Database
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/shougaku"

    # JWT
    secret_key: str = "dev-secret-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    # Firebase
    firebase_project_id: str = ""
    firebase_credentials_path: Optional[str] = None

    # API
    api_version: str = "v1"
    debug: bool = False

    # Sentry
    sentry_dsn: Optional[str] = None
    environment: str = "development"

    class Config:
        env_file = ".env"
        case_sensitive = False  # Allow DATABASE_URL → database_url mapping


@lru_cache()
def get_settings() -> Settings:
    return Settings()
