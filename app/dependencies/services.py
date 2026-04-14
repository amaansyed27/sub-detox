from __future__ import annotations

import os

from app.core.settings import settings
from app.services.aa_gateway_service import AAGatewayService
from app.services.analysis_service import SubscriptionAnalysisService
from app.services.datastore import BaseDataStore, FirestoreDataStore, InMemoryDataStore
from app.services.firebase_runtime import get_firestore_client
from app.services.gemini_analysis_service import GeminiAnalysisService
from app.services.gemini_chat_service import GeminiChatService
from app.services.mock_aa_service import MockAAService


_store: BaseDataStore | None = None
_gateway: AAGatewayService | None = None


def _env_bool(name: str, default: bool) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def get_data_store() -> BaseDataStore:
    global _store
    if _store is not None:
        return _store

    if _env_bool("USE_IN_MEMORY_STORE", False):
        _store = InMemoryDataStore()
        return _store

    _store = FirestoreDataStore(get_firestore_client())
    return _store


def get_gateway_service() -> AAGatewayService:
    global _gateway
    if _gateway is not None:
        return _gateway

    gemini_service = None
    if settings.gemini_analysis_enabled and settings.gemini_api_key.strip():
        gemini_service = GeminiAnalysisService(
            api_key=settings.gemini_api_key,
            model=settings.gemini_model,
            timeout_seconds=settings.gemini_timeout_seconds,
        )

    gemini_chat_service = None
    if settings.gemini_chat_enabled and settings.gemini_api_key.strip():
        gemini_chat_service = GeminiChatService(
            api_key=settings.gemini_api_key,
            model=settings.gemini_chat_model,
            timeout_seconds=settings.gemini_timeout_seconds,
            grounding_enabled=settings.gemini_chat_grounding_enabled,
        )

    _gateway = AAGatewayService(
        store=get_data_store(),
        analysis_service=SubscriptionAnalysisService(),
        mock_aa_service=MockAAService(),
        gemini_analysis_service=gemini_service,
        gemini_chat_service=gemini_chat_service,
    )
    return _gateway
