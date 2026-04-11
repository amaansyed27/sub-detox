from fastapi import APIRouter

from app.schemas.aa import AAMockDataResponse
from app.services.mock_aa_service import MockAAService


router = APIRouter(prefix="/mock-aa-data", tags=["mock-aa-data"])
mock_aa_service = MockAAService()


@router.get(
    "/",
    response_model=AAMockDataResponse,
    summary="Get mocked Account Aggregator transaction payload",
)
def get_mock_aa_data() -> AAMockDataResponse:
    return mock_aa_service.generate_mock_payload()
