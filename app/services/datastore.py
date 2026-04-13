from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class BaseDataStore:
    def upsert_user(self, user_id: str, email: str | None, phone_number: str | None) -> None:
        raise NotImplementedError

    def get_user_profile(self, user_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    def set_user_selected_accounts(
        self,
        user_id: str,
        mobile_number: str,
        selected_accounts: list[dict[str, Any]],
    ) -> None:
        raise NotImplementedError

    def get_user_selected_accounts(self, user_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    def create_consent(self, record: dict[str, Any]) -> None:
        raise NotImplementedError

    def get_consent(self, user_id: str, consent_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    def update_consent(
        self, user_id: str, consent_id: str, updates: dict[str, Any]
    ) -> dict[str, Any] | None:
        raise NotImplementedError

    def create_data_session(self, record: dict[str, Any]) -> None:
        raise NotImplementedError

    def get_data_session(self, user_id: str, session_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    def update_data_session(
        self, user_id: str, session_id: str, updates: dict[str, Any]
    ) -> dict[str, Any] | None:
        raise NotImplementedError

    def list_data_sessions_by_consent(
        self, user_id: str, consent_id: str
    ) -> list[dict[str, Any]]:
        raise NotImplementedError

    def add_webhook_event(self, record: dict[str, Any]) -> None:
        raise NotImplementedError

    def list_webhook_events(self, user_id: str, limit: int) -> list[dict[str, Any]]:
        raise NotImplementedError

    def create_analysis_run(self, record: dict[str, Any]) -> str:
        raise NotImplementedError

    def get_latest_analysis_run(self, user_id: str) -> dict[str, Any] | None:
        raise NotImplementedError

    def upsert_detected_subscription(
        self, user_id: str, merchant_code: str, record: dict[str, Any]
    ) -> None:
        raise NotImplementedError

    def get_detected_subscription(
        self, user_id: str, merchant_code: str
    ) -> dict[str, Any] | None:
        raise NotImplementedError

    def list_detected_subscriptions(self, user_id: str) -> list[dict[str, Any]]:
        raise NotImplementedError

    def mark_subscription_resolved(self, user_id: str, merchant_code: str) -> dict[str, Any] | None:
        raise NotImplementedError

    def create_revoke_action(self, record: dict[str, Any]) -> None:
        raise NotImplementedError

    def create_audit_event(self, record: dict[str, Any]) -> None:
        raise NotImplementedError


@dataclass
class InMemoryDataStore(BaseDataStore):
    users: dict[str, dict[str, Any]] = field(default_factory=dict)
    consents: dict[str, dict[str, Any]] = field(default_factory=dict)
    sessions: dict[str, dict[str, Any]] = field(default_factory=dict)
    webhook_events: list[dict[str, Any]] = field(default_factory=list)
    analysis_runs: dict[str, dict[str, Any]] = field(default_factory=dict)
    detected_subscriptions: dict[str, dict[str, Any]] = field(default_factory=dict)
    revoke_actions: list[dict[str, Any]] = field(default_factory=list)
    audit_events: list[dict[str, Any]] = field(default_factory=list)

    def upsert_user(self, user_id: str, email: str | None, phone_number: str | None) -> None:
        current = self.users.get(user_id, {})
        now = utc_now()
        self.users[user_id] = {
            "userId": user_id,
            "email": email,
            "phoneNumber": phone_number,
            "selectedAccounts": deepcopy(current.get("selectedAccounts", [])),
            "selectionMobileNumber": current.get("selectionMobileNumber"),
            "selectionUpdatedAt": current.get("selectionUpdatedAt"),
            "createdAt": current.get("createdAt", now),
            "updatedAt": now,
        }

    def get_user_profile(self, user_id: str) -> dict[str, Any] | None:
        user = self.users.get(user_id)
        return deepcopy(user) if user else None

    def set_user_selected_accounts(
        self,
        user_id: str,
        mobile_number: str,
        selected_accounts: list[dict[str, Any]],
    ) -> None:
        now = utc_now()
        current = deepcopy(self.users.get(user_id, {}))
        self.users[user_id] = {
            "userId": user_id,
            "email": current.get("email"),
            "phoneNumber": current.get("phoneNumber"),
            "selectedAccounts": deepcopy(selected_accounts),
            "selectionMobileNumber": mobile_number,
            "selectionUpdatedAt": now,
            "createdAt": current.get("createdAt", now),
            "updatedAt": now,
        }

    def get_user_selected_accounts(self, user_id: str) -> dict[str, Any] | None:
        user = self.users.get(user_id)
        if not user:
            return None
        selected_accounts = user.get("selectedAccounts")
        if not isinstance(selected_accounts, list):
            return None
        return {
            "mobileNumber": user.get("selectionMobileNumber"),
            "selectedAccounts": deepcopy(selected_accounts),
            "updatedAt": user.get("selectionUpdatedAt"),
        }

    def create_consent(self, record: dict[str, Any]) -> None:
        self.consents[record["id"]] = deepcopy(record)

    def get_consent(self, user_id: str, consent_id: str) -> dict[str, Any] | None:
        record = self.consents.get(consent_id)
        if not record or record.get("userId") != user_id:
            return None
        return deepcopy(record)

    def update_consent(
        self, user_id: str, consent_id: str, updates: dict[str, Any]
    ) -> dict[str, Any] | None:
        existing = self.consents.get(consent_id)
        if not existing or existing.get("userId") != user_id:
            return None
        existing.update(deepcopy(updates))
        existing["updatedAt"] = utc_now()
        self.consents[consent_id] = existing
        return deepcopy(existing)

    def create_data_session(self, record: dict[str, Any]) -> None:
        self.sessions[record["id"]] = deepcopy(record)

    def get_data_session(self, user_id: str, session_id: str) -> dict[str, Any] | None:
        record = self.sessions.get(session_id)
        if not record or record.get("userId") != user_id:
            return None
        return deepcopy(record)

    def update_data_session(
        self, user_id: str, session_id: str, updates: dict[str, Any]
    ) -> dict[str, Any] | None:
        existing = self.sessions.get(session_id)
        if not existing or existing.get("userId") != user_id:
            return None
        existing.update(deepcopy(updates))
        existing["updatedAt"] = utc_now()
        self.sessions[session_id] = existing
        return deepcopy(existing)

    def list_data_sessions_by_consent(
        self, user_id: str, consent_id: str
    ) -> list[dict[str, Any]]:
        rows = [
            deepcopy(value)
            for value in self.sessions.values()
            if value.get("userId") == user_id and value.get("consentId") == consent_id
        ]
        rows.sort(key=lambda row: row.get("createdAt", utc_now()), reverse=True)
        return rows

    def add_webhook_event(self, record: dict[str, Any]) -> None:
        self.webhook_events.append(deepcopy(record))

    def list_webhook_events(self, user_id: str, limit: int) -> list[dict[str, Any]]:
        rows = [deepcopy(row) for row in self.webhook_events if row.get("userId") == user_id]
        rows.sort(key=lambda row: row.get("createdAt", utc_now()), reverse=True)
        return rows[:limit]

    def create_analysis_run(self, record: dict[str, Any]) -> str:
        run_id = record["runId"]
        self.analysis_runs[run_id] = deepcopy(record)
        return run_id

    def get_latest_analysis_run(self, user_id: str) -> dict[str, Any] | None:
        rows = [
            deepcopy(value)
            for value in self.analysis_runs.values()
            if value.get("userId") == user_id
        ]
        if not rows:
            return None
        rows.sort(key=lambda row: row.get("generatedAt", utc_now()), reverse=True)
        return rows[0]

    def upsert_detected_subscription(
        self, user_id: str, merchant_code: str, record: dict[str, Any]
    ) -> None:
        key = f"{user_id}_{merchant_code}"
        merged = deepcopy(record)
        merged["id"] = key
        self.detected_subscriptions[key] = merged

    def get_detected_subscription(
        self, user_id: str, merchant_code: str
    ) -> dict[str, Any] | None:
        key = f"{user_id}_{merchant_code}"
        row = self.detected_subscriptions.get(key)
        return deepcopy(row) if row else None

    def list_detected_subscriptions(self, user_id: str) -> list[dict[str, Any]]:
        rows = [
            deepcopy(value)
            for value in self.detected_subscriptions.values()
            if value.get("userId") == user_id
        ]
        rows.sort(
            key=lambda row: float(row.get("estimatedMonthlyAmount", 0.0)),
            reverse=True,
        )
        return rows

    def mark_subscription_resolved(self, user_id: str, merchant_code: str) -> dict[str, Any] | None:
        key = f"{user_id}_{merchant_code}"
        row = self.detected_subscriptions.get(key)
        if not row:
            return None
        row["resolved"] = True
        row["resolvedAt"] = utc_now()
        row["updatedAt"] = utc_now()
        self.detected_subscriptions[key] = row
        return deepcopy(row)

    def create_revoke_action(self, record: dict[str, Any]) -> None:
        self.revoke_actions.append(deepcopy(record))

    def create_audit_event(self, record: dict[str, Any]) -> None:
        self.audit_events.append(deepcopy(record))


class FirestoreDataStore(BaseDataStore):
    def __init__(self, db: Any):
        self._db = db

    def upsert_user(self, user_id: str, email: str | None, phone_number: str | None) -> None:
        self._db.collection("users").document(user_id).set(
            {
                "userId": user_id,
                "email": email,
                "phoneNumber": phone_number,
                "updatedAt": utc_now(),
                "createdAt": utc_now(),
            },
            merge=True,
        )

    def get_user_profile(self, user_id: str) -> dict[str, Any] | None:
        doc = self._db.collection("users").document(user_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        return {"id": doc.id, **data}

    def set_user_selected_accounts(
        self,
        user_id: str,
        mobile_number: str,
        selected_accounts: list[dict[str, Any]],
    ) -> None:
        self._db.collection("users").document(user_id).set(
            {
                "selectionMobileNumber": mobile_number,
                "selectedAccounts": deepcopy(selected_accounts),
                "selectionUpdatedAt": utc_now(),
                "updatedAt": utc_now(),
            },
            merge=True,
        )

    def get_user_selected_accounts(self, user_id: str) -> dict[str, Any] | None:
        doc = self._db.collection("users").document(user_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        selected_accounts = data.get("selectedAccounts")
        if not isinstance(selected_accounts, list):
            return None
        return {
            "mobileNumber": data.get("selectionMobileNumber"),
            "selectedAccounts": deepcopy(selected_accounts),
            "updatedAt": data.get("selectionUpdatedAt"),
        }

    def create_consent(self, record: dict[str, Any]) -> None:
        self._db.collection("consents").document(record["id"]).set(record)

    def get_consent(self, user_id: str, consent_id: str) -> dict[str, Any] | None:
        doc = self._db.collection("consents").document(consent_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        if data.get("userId") != user_id:
            return None
        return {"id": doc.id, **data}

    def update_consent(
        self, user_id: str, consent_id: str, updates: dict[str, Any]
    ) -> dict[str, Any] | None:
        existing = self.get_consent(user_id, consent_id)
        if not existing:
            return None
        updates = {**updates, "updatedAt": utc_now()}
        self._db.collection("consents").document(consent_id).set(updates, merge=True)
        merged = {**existing, **updates}
        return merged

    def create_data_session(self, record: dict[str, Any]) -> None:
        self._db.collection("fi_sessions").document(record["id"]).set(record)

    def get_data_session(self, user_id: str, session_id: str) -> dict[str, Any] | None:
        doc = self._db.collection("fi_sessions").document(session_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        if data.get("userId") != user_id:
            return None
        return {"id": doc.id, **data}

    def update_data_session(
        self, user_id: str, session_id: str, updates: dict[str, Any]
    ) -> dict[str, Any] | None:
        existing = self.get_data_session(user_id, session_id)
        if not existing:
            return None
        updates = {**updates, "updatedAt": utc_now()}
        self._db.collection("fi_sessions").document(session_id).set(updates, merge=True)
        merged = {**existing, **updates}
        return merged

    def list_data_sessions_by_consent(
        self, user_id: str, consent_id: str
    ) -> list[dict[str, Any]]:
        snapshot = (
            self._db.collection("fi_sessions")
            .where("userId", "==", user_id)
            .where("consentId", "==", consent_id)
            .order_by("createdAt", direction="DESCENDING")
            .get()
        )
        return [{"id": doc.id, **(doc.to_dict() or {})} for doc in snapshot]

    def add_webhook_event(self, record: dict[str, Any]) -> None:
        self._db.collection("webhook_events").add(record)

    def list_webhook_events(self, user_id: str, limit: int) -> list[dict[str, Any]]:
        snapshot = (
            self._db.collection("webhook_events")
            .where("userId", "==", user_id)
            .order_by("createdAt", direction="DESCENDING")
            .limit(limit)
            .get()
        )
        return [{"id": doc.id, **(doc.to_dict() or {})} for doc in snapshot]

    def create_analysis_run(self, record: dict[str, Any]) -> str:
        ref = self._db.collection("analysis_runs").document(record["runId"])
        ref.set(record)
        return ref.id

    def get_latest_analysis_run(self, user_id: str) -> dict[str, Any] | None:
        snapshot = (
            self._db.collection("analysis_runs")
            .where("userId", "==", user_id)
            .order_by("generatedAt", direction="DESCENDING")
            .limit(1)
            .get()
        )
        if not snapshot:
            return None
        doc = snapshot[0]
        return {"id": doc.id, **(doc.to_dict() or {})}

    def upsert_detected_subscription(
        self, user_id: str, merchant_code: str, record: dict[str, Any]
    ) -> None:
        doc_id = f"{user_id}_{merchant_code}"
        self._db.collection("detected_subscriptions").document(doc_id).set(record, merge=True)

    def get_detected_subscription(
        self, user_id: str, merchant_code: str
    ) -> dict[str, Any] | None:
        doc_id = f"{user_id}_{merchant_code}"
        doc = self._db.collection("detected_subscriptions").document(doc_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        if data.get("userId") != user_id:
            return None
        return {"id": doc.id, **data}

    def list_detected_subscriptions(self, user_id: str) -> list[dict[str, Any]]:
        snapshot = (
            self._db.collection("detected_subscriptions")
            .where("userId", "==", user_id)
            .order_by("estimatedMonthlyAmount", direction="DESCENDING")
            .get()
        )
        return [{"id": doc.id, **(doc.to_dict() or {})} for doc in snapshot]

    def mark_subscription_resolved(self, user_id: str, merchant_code: str) -> dict[str, Any] | None:
        doc_id = f"{user_id}_{merchant_code}"
        ref = self._db.collection("detected_subscriptions").document(doc_id)
        doc = ref.get()
        if not doc.exists:
            return None
        data = doc.to_dict() or {}
        if data.get("userId") != user_id:
            return None
        updates = {
            "resolved": True,
            "resolvedAt": utc_now(),
            "updatedAt": utc_now(),
        }
        ref.set(updates, merge=True)
        return {"id": doc_id, **data, **updates}

    def create_revoke_action(self, record: dict[str, Any]) -> None:
        self._db.collection("revoke_actions").add(record)

    def create_audit_event(self, record: dict[str, Any]) -> None:
        self._db.collection("audit_events").add(record)
