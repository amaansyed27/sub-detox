from fastapi import APIRouter

from app.api.v1.endpoints.analysis import router as analysis_router
from app.api.v1.endpoints.mock_data import router as mock_data_router


api_router = APIRouter(prefix="/api")
api_router.include_router(mock_data_router)
api_router.include_router(analysis_router)
