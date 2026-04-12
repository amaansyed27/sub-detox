from __future__ import annotations

from dataclasses import dataclass
from typing import Annotated

from fastapi import Header, HTTPException, status
from firebase_admin import exceptions as firebase_exceptions

from app.core.settings import settings
from app.services.firebase_runtime import verify_firebase_token


@dataclass(frozen=True)
class CurrentUser:
    uid: str
    email: str | None
    phone_number: str | None


def _extract_bearer_token(authorization: str | None) -> str:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header.",
        )

    prefix = "Bearer "
    if not authorization.startswith(prefix):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header must use Bearer token.",
        )

    token = authorization[len(prefix) :].strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Empty bearer token.",
        )
    return token


def get_current_user(
    authorization: Annotated[str | None, Header(alias="Authorization")] = None,
    x_dev_user: Annotated[str | None, Header(alias="X-Dev-User")] = None,
) -> CurrentUser:
    if settings.auth_bypass_enabled and x_dev_user:
        return CurrentUser(uid=x_dev_user, email=None, phone_number=None)

    token = _extract_bearer_token(authorization)

    try:
        decoded = verify_firebase_token(token)
    except (ValueError, firebase_exceptions.FirebaseError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired Firebase token.",
        )

    uid = decoded.get("uid")
    if not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token does not contain uid.",
        )

    return CurrentUser(
        uid=uid,
        email=decoded.get("email"),
        phone_number=decoded.get("phone_number"),
    )
