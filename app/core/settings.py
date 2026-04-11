from pydantic import BaseModel, Field


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
            "http://127.0.0.1",
            "http://127.0.0.1:3000",
            "http://127.0.0.1:8080",
        ]
    )
    cors_allow_origin_regex: str = r"https?://(localhost|127\\.0\\.0\\.1)(:\\d+)?"


settings = Settings()
