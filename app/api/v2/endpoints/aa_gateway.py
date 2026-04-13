from __future__ import annotations

from typing import Annotated
from uuid import uuid4

from fastapi import APIRouter, Depends, Query, Request
from fastapi.responses import HTMLResponse

from app.dependencies.auth import CurrentUser, get_current_user
from app.dependencies.services import get_gateway_service
from app.schemas.aa_v2 import (
    AccountAvailabilityRequest,
    AccountAvailabilityResponse,
    AccountSelectionRequest,
    AccountSelectionResponse,
    ConsentCollectionRequest,
    ConsentCollectionResponse,
    ConsentDataSessionsResponse,
    ConsentResponse,
    CreateConsentRequest,
    CreateDataSessionRequest,
    DataSessionCreateResponse,
    FipListResponse,
    LastFetchStatusResponse,
    RevokeConsentResponse,
    SessionFetchResponse,
    SimulateConsentActionRequest,
)
from app.services.aa_gateway_service import AAGatewayService


router = APIRouter(prefix="/v2", tags=["aa-v2"])

CurrentUserDep = Annotated[CurrentUser, Depends(get_current_user)]
GatewayDep = Annotated[AAGatewayService, Depends(get_gateway_service)]


@router.post("/account-availability", response_model=AccountAvailabilityResponse)
def account_availability(
    request_body: AccountAvailabilityRequest,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> AccountAvailabilityResponse:
    return gateway.account_availability(user=user, mobile_number=request_body.mobile_number)


@router.post("/account-selection", response_model=AccountSelectionResponse)
def save_account_selection(
    request_body: AccountSelectionRequest,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> AccountSelectionResponse:
    return gateway.save_account_selection(user=user, request_body=request_body)


@router.get("/fips", response_model=FipListResponse)
def list_fips(
    gateway: GatewayDep,
    _user: CurrentUserDep,
    status_filter: Annotated[str | None, Query(alias="status")] = None,
    aa: Annotated[str | None, Query()] = None,
    expanded: Annotated[bool, Query()] = False,
) -> FipListResponse:
    return gateway.list_active_fips(status_filter=status_filter, aa=aa, expanded=expanded)


@router.get("/fips/{fip_id}", response_model=FipListResponse)
def get_fip_by_id(
    fip_id: str,
    gateway: GatewayDep,
    _user: CurrentUserDep,
    aa: Annotated[str | None, Query()] = None,
    expanded: Annotated[bool, Query()] = False,
) -> FipListResponse:
    return gateway.get_fip_by_id(fip_id=fip_id, aa=aa, expanded=expanded)


@router.post("/consents", response_model=ConsentResponse)
def create_consent(
    request: Request,
    request_body: CreateConsentRequest,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> ConsentResponse:
    return gateway.create_consent(
        user=user,
        request_body=request_body,
        public_base_url=str(request.base_url).rstrip("/"),
    )


@router.get("/consents/{consent_id}", response_model=ConsentResponse)
def get_consent(
    consent_id: str,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> ConsentResponse:
    return gateway.get_consent(user=user, consent_id=consent_id)


@router.post("/consents/{consent_id}/revoke", response_model=RevokeConsentResponse)
def revoke_consent(
    consent_id: str,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> RevokeConsentResponse:
    return gateway.revoke_consent(user=user, consent_id=consent_id)


@router.get(
    "/consents/{consent_id}/fetch/status",
    response_model=LastFetchStatusResponse,
)
def get_last_fetch_status(
    consent_id: str,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> LastFetchStatusResponse:
    return gateway.get_last_fetch_status(user=user, consent_id=consent_id)


@router.get(
    "/consents/{consent_id}/data-sessions",
    response_model=ConsentDataSessionsResponse,
)
def get_data_sessions_by_consent(
    consent_id: str,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> ConsentDataSessionsResponse:
    return gateway.get_data_sessions_by_consent(user=user, consent_id=consent_id)


@router.post("/consents/collection", response_model=ConsentCollectionResponse)
def create_consent_collection(
    request: Request,
    request_body: ConsentCollectionRequest,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> ConsentCollectionResponse:
    return gateway.create_consent_collection(
        user=user,
        request_body=request_body,
        public_base_url=str(request.base_url).rstrip("/"),
    )


@router.post("/sessions", response_model=DataSessionCreateResponse)
def create_data_session(
    request_body: CreateDataSessionRequest,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> DataSessionCreateResponse:
    return gateway.create_data_session(user=user, request_body=request_body)


@router.get("/sessions/{session_id}", response_model=SessionFetchResponse)
def fetch_data_session(
    session_id: str,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> SessionFetchResponse:
    return gateway.fetch_data_session(user=user, session_id=session_id)


@router.get("/consents/webview/{consent_id}", response_class=HTMLResponse)
def hosted_consent_webview(consent_id: str) -> HTMLResponse:
    html = f"""
<!doctype html>
<html lang=\"en\">
  <head>
    <meta charset=\"utf-8\" />
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
    <title>Consent Review {consent_id}</title>
    <style>
      body {{ font-family: Arial, sans-serif; max-width: 760px; margin: 40px auto; padding: 0 16px; }}
      .card {{ background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; }}
      button {{ border: 0; border-radius: 8px; padding: 10px 14px; margin-right: 10px; cursor: pointer; }}
      .ok {{ background: #16a34a; color: #fff; }}
      .deny {{ background: #dc2626; color: #fff; }}
    </style>
  </head>
  <body>
    <h2>SubDetox Consent Review</h2>
    <div class=\"card\">
      <p><strong>Consent ID:</strong> {consent_id}</p>
      <p>This hosted-like page emulates AA consent review UX for sandbox testing.</p>
      <p>Use authenticated simulator endpoints to approve/reject this consent:</p>
      <code>POST /v2/simulator/consents/{consent_id}/action</code>
      <p style=\"margin-top: 16px;\">Sample payload:</p>
      <pre>{{ \"action\": \"approve\" }}</pre>
      <p>Supported actions: approve, reject, pause, resume</p>
    </div>
  </body>
</html>
"""
    return HTMLResponse(content=html)


@router.post("/simulator/consents/{consent_id}/action", response_model=ConsentResponse)
def simulate_consent_action(
    consent_id: str,
    request_body: SimulateConsentActionRequest,
    gateway: GatewayDep,
    user: CurrentUserDep,
) -> ConsentResponse:
    return gateway.simulate_consent_action(
        user=user,
        consent_id=consent_id,
        action=request_body.action,
    )


@router.get("/notifications/events")
def list_notification_events(
    gateway: GatewayDep,
    user: CurrentUserDep,
    limit: Annotated[int, Query(ge=1, le=100)] = 25,
) -> dict[str, object]:
    return {
        "data": gateway.list_webhook_events(user=user, limit=limit),
        "traceId": str(uuid4()),
    }
