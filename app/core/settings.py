import os
from pydantic import BaseModel, Field


def _env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


class Settings(BaseModel):
    app_name: str = "SubDetox Backend"
    app_version: str = "0.1.0"
    app_description: str = (
        "AI-powered transaction auditor that identifies hidden recurring charges "
        "from Account Aggregator transaction feeds."
    )
    cors_allow_origins: list[str] = Field(
        default_factory=lambda: [
            "http://localhost",
            "http://localhost:3000",
            "http://localhost:8080",
            "http://localhost:8081",
            "http://127.0.0.1",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:8080",
            "http://127.0.0.1:8081",
        ]
    )
    cors_allow_origin_regex: str = r"https?://(localhost|127\\.0\\.0\\.1)(:\\d+)?"

    firebase_project_id: str = Field(
        default_factory=lambda: os.getenv("FIREBASE_PROJECT_ID", "subdetox-20260412-8514")
    )
    firestore_emulator_host: str | None = Field(
        default_factory=lambda: os.getenv("FIRESTORE_EMULATOR_HOST")
    )
    use_firestore_emulator: bool = Field(
        default_factory=lambda: _env_bool("USE_FIRESTORE_EMULATOR", False)
    )
    auth_bypass_enabled: bool = Field(
        default_factory=lambda: _env_bool("AUTH_BYPASS_ENABLED", False)
    )
    auth_bypass_header: str = Field(
        default_factory=lambda: os.getenv("AUTH_BYPASS_HEADER", "X-Dev-User")
    )
    webhook_retry_attempts: int = Field(
        default_factory=lambda: int(os.getenv("WEBHOOK_RETRY_ATTEMPTS", "3")),
        ge=1,
        le=10,
    )
    webhook_timeout_seconds: float = Field(
        default_factory=lambda: float(os.getenv("WEBHOOK_TIMEOUT_SECONDS", "4")),
        ge=0.5,
        le=30,
    )
    public_base_url: str = Field(
        default_factory=lambda: os.getenv("PUBLIC_BASE_URL", "http://127.0.0.1:8000")
    )


settings = Settings()
