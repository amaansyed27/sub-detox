from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Body, Depends, HTTPException

from app.dependencies.auth import CurrentUser, get_current_user
from app.dependencies.services import get_gateway_service
from app.schemas.analysis import AnalyzeTransactionsRequest
from app.schemas.chat import (
    ChatAssistRequest,
    ChatAssistResponse,
    ManualUploadRequest,
    ManualUploadResponse,
    ServiceRequestCreateRequest,
    ServiceRequestCreateResponse,
    SupportTicketRequest,
    SupportTicketResponse,
)
from app.services.aa_gateway_service import AAGatewayService


router = APIRouter(tags=["app-api"])

CurrentUserDep = Annotated[CurrentUser, Depends(get_current_user)]
GatewayDep = Annotated[AAGatewayService, Depends(get_gateway_service)]


@router.get("/me")
def get_me(gateway: GatewayDep, user: CurrentUserDep) -> dict[str, object]:
    return gateway.get_user_profile(user)


@router.get("/mock-aa-data")
def mock_aa_data(gateway: GatewayDep, user: CurrentUserDep) -> dict[str, object]:
    return gateway.get_mock_aa_data(user)


@router.post("/analyze-transactions")
def analyze_transactions(
    gateway: GatewayDep,
    user: CurrentUserDep,
    request: Annotated[AnalyzeTransactionsRequest | None, Body()] = None,
) -> dict[str, object]:
    return gateway.analyze_transactions(user=user, aa_payload=request.aa_payload if request else None)


@router.get("/analysis/latest")
def latest_analysis(gateway: GatewayDep, user: CurrentUserDep) -> dict[str, object]:
    latest = gateway.get_latest_analysis(user)
    if latest is None:
        raise HTTPException(status_code=404, detail="No analysis run found for this user.")
    return latest


@router.post("/revoke-mandate")
def revoke_mandate(
    gateway: GatewayDep,
    user: CurrentUserDep,
    body: Annotated[dict[str, str], Body()],
) -> dict[str, object]:
    merchant_code = (body.get("merchant_code") or "").strip()
    if not merchant_code:
        raise HTTPException(status_code=400, detail="merchant_code is required.")
    return gateway.revoke_mandate(user=user, merchant_code=merchant_code)


@router.post("/manual-upload", response_model=ManualUploadResponse)
def manual_upload(
    gateway: GatewayDep,
    user: CurrentUserDep,
    request_body: ManualUploadRequest,
) -> ManualUploadResponse:
    return ManualUploadResponse.model_validate(
        gateway.submit_manual_upload(
            user=user,
            file_name=request_body.file_name,
            content=request_body.content,
            upload_method=request_body.upload_method,
        )
    )


@router.post("/chat/assist", response_model=ChatAssistResponse)
def assist_chat(
    gateway: GatewayDep,
    user: CurrentUserDep,
    request_body: ChatAssistRequest,
) -> ChatAssistResponse:
    return ChatAssistResponse.model_validate(
        gateway.assist_chat(
            user=user,
            message=request_body.message,
            history=[item.model_dump() for item in request_body.history],
        )
    )


@router.post("/chat/tickets", response_model=SupportTicketResponse)
def create_support_ticket(
    gateway: GatewayDep,
    user: CurrentUserDep,
    request_body: SupportTicketRequest,
) -> SupportTicketResponse:
    return SupportTicketResponse.model_validate(
        gateway.create_support_ticket(
            user=user,
            title=request_body.title,
            description=request_body.description,
            category=request_body.category,
            priority=request_body.priority,
        )
    )


@router.post("/chat/requests", response_model=ServiceRequestCreateResponse)
def create_service_request(
    gateway: GatewayDep,
    user: CurrentUserDep,
    request_body: ServiceRequestCreateRequest,
) -> ServiceRequestCreateResponse:
    return ServiceRequestCreateResponse.model_validate(
        gateway.create_service_request(
            user=user,
            request_type=request_body.request_type,
            details=request_body.details,
            account_link_ref_number=request_body.account_link_ref_number,
        )
    )
