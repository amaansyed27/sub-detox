from __future__ import annotations

import os

import pytest
from fastapi.testclient import TestClient

from app.dependencies.auth import CurrentUser, get_current_user
from app.dependencies.services import get_gateway_service
from app.main import app
from app.services.aa_gateway_service import AAGatewayService
from app.services.analysis_service import SubscriptionAnalysisService
from app.services.datastore import InMemoryDataStore
from app.services.mock_aa_service import MockAAService


@pytest.fixture()
def client() -> TestClient:
    os.environ["USE_IN_MEMORY_STORE"] = "true"

    store = InMemoryDataStore()
    gateway = AAGatewayService(
        store=store,
        analysis_service=SubscriptionAnalysisService(),
        mock_aa_service=MockAAService(),
    )

    def _override_user() -> CurrentUser:
        return CurrentUser(
            uid="test-user",
            email="test-user@example.com",
            phone_number="+919999999999",
        )

    def _override_gateway() -> AAGatewayService:
        return gateway

    app.dependency_overrides[get_current_user] = _override_user
    app.dependency_overrides[get_gateway_service] = _override_gateway

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()
