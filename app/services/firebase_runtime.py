from __future__ import annotations

import os
from typing import Any

import firebase_admin
from firebase_admin import auth, firestore

from app.core.settings import settings


def initialize_firebase() -> None:
    if settings.use_firestore_emulator and settings.firestore_emulator_host:
        os.environ["FIRESTORE_EMULATOR_HOST"] = settings.firestore_emulator_host

    if firebase_admin._apps:
        return

    firebase_admin.initialize_app(
        options={
            "projectId": settings.firebase_project_id,
        }
    )


def verify_firebase_token(id_token: str) -> dict[str, Any]:
    initialize_firebase()
    return auth.verify_id_token(id_token, check_revoked=False)


def get_firestore_client() -> firestore.Client:
    initialize_firebase()
    return firestore.client()
