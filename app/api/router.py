from fastapi import APIRouter

from app.api.v1.endpoints.app_api import router as app_api_router
from app.api.v2.endpoints.aa_gateway import router as aa_gateway_router


api_router = APIRouter(prefix="/api")
api_router.include_router(app_api_router)
api_router.include_router(aa_gateway_router)
