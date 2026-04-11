from typing import Annotated

from fastapi import APIRouter, Body

from app.schemas.analysis import AnalyzeTransactionsRequest, AnalyzeTransactionsResponse
from app.services.analysis_service import SubscriptionAnalysisService
from app.services.mock_aa_service import MockAAService


router = APIRouter(prefix="/analyze-transactions", tags=["analysis"])
analysis_service = SubscriptionAnalysisService()
mock_aa_service = MockAAService()


@router.post(
    "/",
    response_model=AnalyzeTransactionsResponse,
    summary="Analyze transactions and detect recurring subscription leakage",
)
def analyze_transactions(
    request: Annotated[AnalyzeTransactionsRequest | None, Body()] = None,
) -> AnalyzeTransactionsResponse:
    payload = (
        request.aa_payload
        if request is not None and request.aa_payload is not None
        else mock_aa_service.generate_mock_payload()
    )
    return analysis_service.analyze(payload)
