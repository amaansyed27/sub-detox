from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.api.v2.endpoints.aa_gateway import router as aa_gateway_router
from app.core.settings import settings
from app.services.firebase_runtime import initialize_firebase


@asynccontextmanager
async def lifespan(_: FastAPI):
    initialize_firebase()
    yield


def create_application() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        version=settings.app_version,
        description=settings.app_description,
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_allow_origins,
        allow_origin_regex=settings.cors_allow_origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router)
    app.include_router(aa_gateway_router)

    @app.get("/health", tags=["health"])
    def health_check() -> dict[str, str]:
        return {
            "status": "ok",
            "service": "subdetox-cloudrun-fastapi",
            "project_id": settings.firebase_project_id,
        }

    return app


app = create_application()
