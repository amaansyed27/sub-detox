from __future__ import annotations

from collections import defaultdict
from datetime import UTC, datetime, timedelta
from decimal import Decimal
import hashlib
import json
from typing import Any
from urllib import error as urllib_error
from urllib import request as urllib_request
from uuid import uuid4

from fastapi import HTTPException, status

from app.core.settings import settings
from app.dependencies.auth import CurrentUser
from app.schemas.aa import AAMockDataResponse
from app.schemas.aa_v2 import (
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
)
from app.services.analysis_service import SubscriptionAnalysisService
from app.services.datastore import BaseDataStore, utc_now
from app.services.mock_aa_service import MockAAService


FIP_CATALOG: tuple[dict[str, Any], ...] = (
    {
        "name": "Setu FIP",
        "fipId": "setu-fip",
        "fiTypes": ["DEPOSIT"],
        "institutionType": "BANK",
        "status": "ACTIVE",
        "otpMode": "DYNAMIC",
    },
    {
        "name": "Setu FIP 2",
        "fipId": "setu-fip-2",
        "fiTypes": ["DEPOSIT"],
        "institutionType": "BANK",
        "status": "ACTIVE",
        "otpMode": "STATIC_123456",
    },
    {
        "name": "Axis Bank",
        "fipId": "AXIS001",
        "fiTypes": ["DEPOSIT"],
        "institutionType": "BANK",
        "status": "TEMPORARILY_INACTIVE",
        "otpMode": "UPSTREAM",
    },
)


class AAGatewayService:
    def __init__(
        self,
        store: BaseDataStore,
        analysis_service: SubscriptionAnalysisService | None = None,
        mock_aa_service: MockAAService | None = None,
    ) -> None:
        self._store = store
        self._analysis_service = analysis_service or SubscriptionAnalysisService()
        self._mock_aa_service = mock_aa_service or MockAAService()

    @staticmethod
    def _trace_id() -> str:
        return str(uuid4())

    @staticmethod
    def _notification_id() -> str:
        return str(uuid4())

    @staticmethod
    def _hash_ratio(value: str) -> float:
        digest = hashlib.sha256(value.encode("utf-8")).hexdigest()
        return int(digest[:8], 16) / 0xFFFFFFFF

    @staticmethod
    def _mask_account(account_seed: str) -> str:
        digest = hashlib.sha256(account_seed.encode("utf-8")).hexdigest()
        suffix = str(int(digest[:10], 16) % 10000).zfill(4)
        return f"XXXXXXXX{suffix}"

    @staticmethod
    def _normalize_mobile(mobile_number: str) -> str:
        digits = "".join(ch for ch in mobile_number if ch.isdigit())
        if len(digits) > 10:
            digits = digits[-10:]
        return digits

    @classmethod
    def _extract_mobile_from_vua(cls, vua: str) -> str:
        handle = vua.split("@", 1)[0]
        return cls._normalize_mobile(handle)

    @staticmethod
    def _link_ref_number(account_seed: str) -> str:
        digest = hashlib.sha256(account_seed.encode("utf-8")).hexdigest().upper()
        return f"LNK{digest[:12]}"

    @staticmethod
    def _to_iso(value: Any) -> str:
        if value is None:
            return datetime.now(UTC).isoformat()
        if isinstance(value, datetime):
            return value.astimezone(UTC).isoformat()
        if hasattr(value, "to_pydatetime"):
            return value.to_pydatetime().astimezone(UTC).isoformat()
        return str(value)

    @staticmethod
    def _to_datetime(value: Any) -> datetime:
        if isinstance(value, datetime):
            return value
        if hasattr(value, "to_pydatetime"):
            return value.to_pydatetime()
        if isinstance(value, str):
            return datetime.fromisoformat(value.replace("Z", "+00:00"))
        return utc_now()

    def _deterministic_linked_banks(
        self,
        user: CurrentUser,
        mobile_number: str,
    ) -> list[dict[str, Any]]:
        normalized_mobile = self._normalize_mobile(mobile_number)
        if not normalized_mobile:
            normalized_mobile = mobile_number.strip()

        linked_banks: list[dict[str, Any]] = []
        for fip in FIP_CATALOG:
            seed_base = f"{user.uid}:{normalized_mobile}:{fip['fipId']}"
            include_bank = (
                fip["status"] == "ACTIVE"
                or self._hash_ratio(seed_base + ":include") >= 0.55
            )
            if not include_bank:
                continue

            account_count = 2 if self._hash_ratio(seed_base + ":count") > 0.62 else 1
            accounts: list[dict[str, Any]] = []
            for index in range(account_count):
                account_seed = f"{seed_base}:{index}"
                account_type = "SAVINGS"
                if index == 1 and self._hash_ratio(account_seed + ":type") > 0.45:
                    account_type = "CURRENT"

                accounts.append(
                    {
                        "fipId": fip["fipId"],
                        "linkRefNumber": self._link_ref_number(account_seed),
                        "maskedAccNumber": self._mask_account(account_seed),
                        "accType": account_type,
                        "fiType": "DEPOSIT",
                        "nickname": "Primary" if index == 0 else "Secondary",
                    }
                )

            linked_banks.append(
                {
                    "fipId": fip["fipId"],
                    "bankName": fip["name"],
                    "status": fip["status"],
                    "accounts": accounts,
                }
            )

        if linked_banks:
            return linked_banks

        fallback_fip = FIP_CATALOG[0]
        fallback_seed = f"{user.uid}:{normalized_mobile}:{fallback_fip['fipId']}:0"
        return [
            {
                "fipId": fallback_fip["fipId"],
                "bankName": fallback_fip["name"],
                "status": fallback_fip["status"],
                "accounts": [
                    {
                        "fipId": fallback_fip["fipId"],
                        "linkRefNumber": self._link_ref_number(fallback_seed),
                        "maskedAccNumber": self._mask_account(fallback_seed),
                        "accType": "SAVINGS",
                        "fiType": "DEPOSIT",
                        "nickname": "Primary",
                    }
                ],
            }
        ]

    def list_active_fips(
        self,
        status_filter: str | None,
        aa: str | None,
        expanded: bool,
    ) -> FipListResponse:
        data: list[dict[str, Any]] = []
        for fip in FIP_CATALOG:
            if status_filter and fip["status"] != status_filter:
                continue

            base_key = f"{fip['fipId']}:{aa or 'all'}"
            consent_rate = round(68 + self._hash_ratio(base_key + ":consent") * 30, 2)
            fetch_rate = round(55 + self._hash_ratio(base_key + ":fetch") * 43, 2)
            aa_wise = [
                {
                    "aa": "onemoney",
                    "consentConversionRate": round(min(99.0, consent_rate + 1.5), 2),
                    "dataFetchSuccessRate": round(min(99.0, fetch_rate + 2.5), 2),
                },
                {
                    "aa": "anumati",
                    "consentConversionRate": round(max(35.0, consent_rate - 2.1), 2),
                    "dataFetchSuccessRate": round(max(30.0, fetch_rate - 3.2), 2),
                },
            ]

            entry: dict[str, Any] = {
                "name": fip["name"],
                "fipId": fip["fipId"],
                "fiTypes": fip["fiTypes"],
                "institutionType": fip["institutionType"],
                "status": fip["status"],
                "consentConversionRate": consent_rate,
                "dataFetchSuccessRate": fetch_rate,
                "aaWiseSuccessRate": aa_wise,
            }

            if expanded:
                entry["aaWiseHealthMetrics"] = {
                    "onemoney": [
                        {
                            "eventName": "DISCOVERY",
                            "metrics_as_of": self._to_iso(utc_now()),
                            "latency_avg": 174,
                            "latency_p50": 119,
                            "latency_p95": 460,
                            "latency_p99": 712,
                            "success_rate": round(min(99.0, fetch_rate), 2),
                        },
                        {
                            "eventName": "DATA_FETCH",
                            "metrics_as_of": self._to_iso(utc_now()),
                            "latency_avg": 265,
                            "latency_p50": 221,
                            "latency_p95": 780,
                            "latency_p99": 1011,
                            "success_rate": round(min(99.0, fetch_rate - 1.2), 2),
                        },
                    ]
                }

            data.append(entry)

        return FipListResponse.model_validate({"data": data, "traceId": self._trace_id()})

    def get_fip_by_id(self, fip_id: str, aa: str | None, expanded: bool) -> FipListResponse:
        all_fips = self.list_active_fips(status_filter=None, aa=aa, expanded=expanded)
        filtered = [entry for entry in all_fips.data if entry.fip_id == fip_id]
        if not filtered:
            raise HTTPException(status_code=404, detail="FIP not found.")
        return FipListResponse.model_validate(
            {"data": [entry.model_dump(by_alias=True) for entry in filtered], "traceId": self._trace_id()}
        )

    def account_availability(
        self,
        user: CurrentUser,
        mobile_number: str,
    ) -> AccountAvailabilityResponse:
        normalized_mobile = self._normalize_mobile(mobile_number)
        lookup_mobile = normalized_mobile or mobile_number
        last_digit = (
            int(lookup_mobile[-1]) if lookup_mobile and lookup_mobile[-1].isdigit() else 0
        )
        linked_banks = self._deterministic_linked_banks(user=user, mobile_number=lookup_mobile)
        response = {
            "accounts": [
                {
                    "aa": "onemoney",
                    "vua": f"{lookup_mobile}@onemoney",
                    "status": last_digit % 2 == 0,
                },
                {
                    "aa": "setu",
                    "vua": f"{lookup_mobile}@setu",
                    "status": True,
                },
                {
                    "aa": "anumati",
                    "vua": f"{lookup_mobile}@anumati",
                    "status": last_digit % 3 != 1,
                },
            ],
            "linkedBanks": linked_banks,
            "traceId": self._trace_id(),
        }
        return AccountAvailabilityResponse.model_validate(response)

    def save_account_selection(
        self,
        user: CurrentUser,
        request_body: AccountSelectionRequest,
    ) -> AccountSelectionResponse:
        normalized_mobile = self._normalize_mobile(request_body.mobile_number)
        if not normalized_mobile:
            raise HTTPException(status_code=400, detail="Invalid mobile number.")

        requested_refs = [
            ref.strip()
            for ref in request_body.selected_link_ref_numbers
            if ref.strip()
        ]
        if not requested_refs:
            raise HTTPException(
                status_code=400,
                detail="At least one linked account selection is required.",
            )

        linked_banks = self._deterministic_linked_banks(user=user, mobile_number=normalized_mobile)
        discovered_by_ref: dict[str, dict[str, Any]] = {}
        for bank in linked_banks:
            for account in bank.get("accounts", []):
                discovered_by_ref[account["linkRefNumber"]] = account

        selected_accounts: list[dict[str, Any]] = []
        seen_refs: set[str] = set()
        for ref in requested_refs:
            account = discovered_by_ref.get(ref)
            if account is None:
                raise HTTPException(
                    status_code=400,
                    detail=f"Unknown linked account selection: {ref}",
                )
            if ref in seen_refs:
                continue
            seen_refs.add(ref)
            selected_accounts.append(account)

        self._store.set_user_selected_accounts(
            user_id=user.uid,
            mobile_number=normalized_mobile,
            selected_accounts=selected_accounts,
        )
        self._store.create_audit_event(
            {
                "userId": user.uid,
                "eventType": "ACCOUNT_SELECTION_SAVED",
                "mobileNumber": normalized_mobile,
                "selectedAccountCount": len(selected_accounts),
                "createdAt": utc_now(),
            }
        )

        return AccountSelectionResponse.model_validate(
            {
                "status": "SAVED",
                "selectedAccounts": selected_accounts,
                "traceId": self._trace_id(),
            }
        )

    def _compute_expiry(self, request_body: CreateConsentRequest, consent_start: datetime) -> datetime:
        if request_body.consent_duration is not None:
            unit = request_body.consent_duration.unit.upper()
            try:
                value = int(request_body.consent_duration.value)
            except ValueError:
                value = 1
            value = max(1, value)

            if unit == "DAY":
                return consent_start + timedelta(days=value)
            if unit == "MONTH":
                return consent_start + timedelta(days=value * 30)
            if unit == "YEAR":
                return consent_start + timedelta(days=value * 365)

        return consent_start + timedelta(days=120)

    def _selected_fips(self, request_body: CreateConsentRequest) -> list[str]:
        context = {entry.key: entry.value for entry in request_body.context}
        if "fipId" in context:
            selected = [value.strip() for value in context["fipId"].split(",") if value.strip()]
        else:
            selected = ["setu-fip", "setu-fip-2"]

        if "excludeFipIds" in context:
            excluded = {value.strip() for value in context["excludeFipIds"].split(",") if value.strip()}
            selected = [value for value in selected if value not in excluded]

        return selected or ["setu-fip"]

    def _accounts_for_consent(
        self,
        user: CurrentUser,
        request_body: CreateConsentRequest,
        selected_fips: list[str],
    ) -> list[dict[str, Any]]:
        fi_type = request_body.fi_types[0] if request_body.fi_types else "DEPOSIT"
        consent_mobile = self._extract_mobile_from_vua(request_body.vua)

        selected_profile = self._store.get_user_selected_accounts(user.uid)
        selected_accounts: list[dict[str, Any]] = []
        if selected_profile is not None:
            selected_mobile = self._normalize_mobile(
                str(selected_profile.get("mobileNumber") or "")
            )
            if selected_mobile and selected_mobile == consent_mobile:
                for account in selected_profile.get("selectedAccounts", []):
                    if account.get("fipId") not in selected_fips:
                        continue
                    selected_accounts.append(
                        {
                            "maskedAccNumber": account.get("maskedAccNumber"),
                            "accType": account.get("accType", "SAVINGS"),
                            "fipId": account.get("fipId"),
                            "fiType": fi_type,
                            "linkRefNumber": account.get("linkRefNumber"),
                        }
                    )
        if selected_accounts:
            return selected_accounts

        linked_banks = self._deterministic_linked_banks(
            user=user,
            mobile_number=consent_mobile or request_body.vua,
        )
        accounts_by_fip: dict[str, list[dict[str, Any]]] = {}
        for bank in linked_banks:
            fip_id = bank.get("fipId")
            if not isinstance(fip_id, str):
                continue
            accounts_by_fip[fip_id] = bank.get("accounts", [])

        resolved_accounts: list[dict[str, Any]] = []
        for fip_id in selected_fips:
            bank_accounts = accounts_by_fip.get(fip_id, [])
            if bank_accounts:
                primary = bank_accounts[0]
                resolved_accounts.append(
                    {
                        "maskedAccNumber": primary.get("maskedAccNumber"),
                        "accType": primary.get("accType", "SAVINGS"),
                        "fipId": fip_id,
                        "fiType": fi_type,
                        "linkRefNumber": primary.get("linkRefNumber"),
                    }
                )
                continue

            fallback_seed = f"{user.uid}:{consent_mobile}:{fip_id}:consent"
            resolved_accounts.append(
                {
                    "maskedAccNumber": self._mask_account(fallback_seed),
                    "accType": "SAVINGS",
                    "fipId": fip_id,
                    "fiType": fi_type,
                    "linkRefNumber": self._link_ref_number(fallback_seed),
                }
            )

        return resolved_accounts

    def create_consent(
        self,
        user: CurrentUser,
        request_body: CreateConsentRequest,
        public_base_url: str,
    ) -> ConsentResponse:
        consent_id = str(uuid4())
        trace_id = self._trace_id()
        consent_start = utc_now()
        consent_expiry = self._compute_expiry(request_body, consent_start)
        selected_fips = self._selected_fips(request_body)
        accounts = self._accounts_for_consent(
            user=user,
            request_body=request_body,
            selected_fips=selected_fips,
        )

        tags = request_body.additional_params.tags if request_body.additional_params else []
        notification_url = (
            request_body.additional_params.notification_url
            if request_body.additional_params is not None
            else None
        )

        consent_record: dict[str, Any] = {
            "id": consent_id,
            "userId": user.uid,
            "url": f"{public_base_url.rstrip('/')}/v2/consents/webview/{consent_id}",
            "status": "PENDING",
            "context": [entry.model_dump(by_alias=True) for entry in request_body.context],
            "detail": {
                "purpose": request_body.purpose
                or {
                    "refUri": "https://api.rebit.org.in/aa/purpose/101.xml",
                    "code": "101",
                    "text": "Loan underwriting",
                    "category": {"type": "string"},
                },
                "consentStart": self._to_iso(consent_start),
                "consentExpiry": self._to_iso(consent_expiry),
                "consentMode": request_body.consent_mode,
                "fetchType": request_body.fetch_type,
                "consentTypes": request_body.consent_types,
                "fiTypes": request_body.fi_types,
                "vua": request_body.vua,
                "dataRange": request_body.data_range.model_dump(by_alias=True),
                "dataLife": (
                    request_body.data_life.model_dump(by_alias=True)
                    if request_body.data_life is not None
                    else {"unit": "MONTH", "value": "6"}
                ),
                "frequency": (
                    request_body.frequency.model_dump(by_alias=True)
                    if request_body.frequency is not None
                    else {"unit": "MONTH", "value": "1"}
                ),
            },
            "accountsLinked": accounts,
            "tags": tags,
            "traceId": trace_id,
            "notificationUrl": notification_url,
            "createdAt": consent_start,
            "updatedAt": consent_start,
        }

        self._store.upsert_user(user.uid, user.email, user.phone_number)
        self._store.create_consent(consent_record)
        self._store.create_audit_event(
            {
                "userId": user.uid,
                "eventType": "CONSENT_CREATED",
                "consentId": consent_id,
                "status": "PENDING",
                "createdAt": utc_now(),
            }
        )

        return self._consent_to_response(consent_record)

    def get_consent(self, user: CurrentUser, consent_id: str) -> ConsentResponse:
        consent = self._store.get_consent(user.uid, consent_id)
        if consent is None:
            raise HTTPException(status_code=404, detail="Consent not found.")
        return self._consent_to_response(consent)

    def _emit_webhook(
        self,
        user_id: str,
        payload: dict[str, Any],
        callback_url: str | None,
    ) -> None:
        status_value = "SKIPPED"
        error_message: str | None = None
        attempts = 0

        if callback_url:
            body = json.dumps(payload).encode("utf-8")
            request_obj = urllib_request.Request(
                callback_url,
                data=body,
                headers={"Content-Type": "application/json"},
                method="POST",
            )

            for attempt in range(1, settings.webhook_retry_attempts + 1):
                attempts = attempt
                try:
                    with urllib_request.urlopen(
                        request_obj,
                        timeout=settings.webhook_timeout_seconds,
                    ) as response:
                        if 200 <= response.status < 300:
                            status_value = "DELIVERED"
                            error_message = None
                            break
                        status_value = "FAILED"
                        error_message = f"HTTP {response.status}"
                except urllib_error.URLError as exc:
                    status_value = "FAILED"
                    error_message = str(exc)

        self._store.add_webhook_event(
            {
                "userId": user_id,
                "payload": payload,
                "callbackUrl": callback_url,
                "deliveryStatus": status_value,
                "attempts": attempts,
                "error": error_message,
                "createdAt": utc_now(),
            }
        )

    def simulate_consent_action(
        self,
        user: CurrentUser,
        consent_id: str,
        action: str,
    ) -> ConsentResponse:
        consent = self._store.get_consent(user.uid, consent_id)
        if consent is None:
            raise HTTPException(status_code=404, detail="Consent not found.")

        action_map = {
            "approve": "ACTIVE",
            "reject": "REJECTED",
            "pause": "PAUSED",
            "resume": "ACTIVE",
        }
        if action not in action_map:
            raise HTTPException(status_code=400, detail="Unsupported action.")

        next_status = action_map[action]
        updated = self._store.update_consent(
            user.uid,
            consent_id,
            {
                "status": next_status,
                "updatedAt": utc_now(),
            },
        )
        if updated is None:
            raise HTTPException(status_code=404, detail="Consent not found.")

        error_payload = None
        success = True
        if next_status == "REJECTED":
            success = False
            error_payload = {
                "code": "UserRejected",
                "message": "reject_other",
            }

        webhook_payload = {
            "data": {
                "status": next_status,
                "detail": {
                    "accounts": updated.get("accountsLinked", []),
                    "vua": updated.get("detail", {}).get("vua"),
                },
            },
            "timestamp": self._to_iso(utc_now()),
            "success": success,
            "type": "CONSENT_STATUS_UPDATE",
            "error": error_payload,
            "consentId": consent_id,
            "notificationId": self._notification_id(),
        }
        self._emit_webhook(user.uid, webhook_payload, updated.get("notificationUrl"))

        self._store.create_audit_event(
            {
                "userId": user.uid,
                "eventType": "CONSENT_STATUS_CHANGED",
                "consentId": consent_id,
                "status": next_status,
                "createdAt": utc_now(),
            }
        )

        return self._consent_to_response(updated)

    def revoke_consent(self, user: CurrentUser, consent_id: str) -> RevokeConsentResponse:
        consent = self._store.get_consent(user.uid, consent_id)
        if consent is None:
            raise HTTPException(status_code=404, detail="Consent not found.")

        updated = self._store.update_consent(user.uid, consent_id, {"status": "REVOKED"})
        if updated is None:
            raise HTTPException(status_code=404, detail="Consent not found.")

        webhook_payload = {
            "data": {
                "status": "REVOKED",
                "detail": {
                    "accounts": updated.get("accountsLinked", []),
                    "vua": updated.get("detail", {}).get("vua"),
                },
            },
            "timestamp": self._to_iso(utc_now()),
            "success": True,
            "type": "CONSENT_STATUS_UPDATE",
            "error": None,
            "consentId": consent_id,
            "notificationId": self._notification_id(),
        }
        self._emit_webhook(user.uid, webhook_payload, updated.get("notificationUrl"))

        return RevokeConsentResponse.model_validate(
            {
                "status": "REVOKED",
                "traceId": self._trace_id(),
            }
        )

    @staticmethod
    def _combined_session_status(statuses: list[str]) -> str:
        normalized = [status.upper() for status in statuses]
        if all(status in {"READY", "DELIVERED"} for status in normalized):
            return "COMPLETED"
        if any(status in {"READY", "DELIVERED"} for status in normalized):
            return "PARTIAL"
        if any(status == "PENDING" for status in normalized):
            return "PENDING"
        if any(status == "EXPIRED" for status in normalized):
            return "EXPIRED"
        return "FAILED"

    def create_data_session(
        self,
        user: CurrentUser,
        request_body: CreateDataSessionRequest,
    ) -> DataSessionCreateResponse:
        consent = self._store.get_consent(user.uid, request_body.consent_id)
        if consent is None:
            raise HTTPException(status_code=404, detail="Consent not found.")
        if consent.get("status") != "ACTIVE":
            raise HTTPException(
                status_code=400,
                detail="Consent must be ACTIVE before data session creation.",
            )

        session_id = str(uuid4())
        trace_id = self._trace_id()
        account_states: list[dict[str, Any]] = []
        for account in consent.get("accountsLinked", []):
            fip_id = account.get("fipId", "setu-fip")
            entropy = self._hash_ratio(f"{session_id}:{account.get('linkRefNumber', '')}")
            if fip_id == "setu-fip-2":
                planned_status = "TIMEOUT" if entropy < 0.35 else "READY"
            elif fip_id == "AXIS001":
                planned_status = "DENIED" if entropy < 0.6 else "READY"
            else:
                planned_status = "READY" if entropy < 0.9 else "PENDING"

            account_states.append(
                {
                    "fipId": fip_id,
                    "linkRefNumber": account.get("linkRefNumber"),
                    "maskedAccNumber": account.get("maskedAccNumber"),
                    "plannedStatus": planned_status,
                    "FIStatus": "PENDING",
                    "description": "Awaiting FIP response",
                }
            )

        session_record = {
            "id": session_id,
            "userId": user.uid,
            "consentId": request_body.consent_id,
            "status": "PENDING",
            "format": request_body.format,
            "dataRange": request_body.data_range.model_dump(by_alias=True),
            "accounts": account_states,
            "traceId": trace_id,
            "lastFetchedAt": None,
            "createdAt": utc_now(),
            "updatedAt": utc_now(),
            "notificationUrl": consent.get("notificationUrl"),
        }
        self._store.create_data_session(session_record)

        webhook_payload = {
            "data": {
                "status": "PENDING",
                "fips": [
                    {
                        "fipID": account["fipId"],
                        "accounts": [
                            {
                                "linkRefNumber": account["linkRefNumber"],
                                "description": account["description"],
                                "FIStatus": account["FIStatus"],
                            }
                        ],
                    }
                    for account in account_states
                ],
                "format": request_body.format,
            },
            "timestamp": self._to_iso(utc_now()),
            "dataSessionId": session_id,
            "success": True,
            "type": "SESSION_STATUS_UPDATE",
            "error": None,
            "consentId": request_body.consent_id,
            "notificationId": self._notification_id(),
        }
        self._emit_webhook(user.uid, webhook_payload, consent.get("notificationUrl"))

        return DataSessionCreateResponse.model_validate(
            {
                "id": session_id,
                "status": "PENDING",
                "format": request_body.format,
                "consentId": request_body.consent_id,
                "dataRange": request_body.data_range.model_dump(by_alias=True),
                "traceId": trace_id,
            }
        )

    def _mock_fi_data(self, account_state: dict[str, Any]) -> dict[str, Any]:
        mock_payload: AAMockDataResponse = self._mock_aa_service.generate_mock_payload()
        fi_record = mock_payload.fi[0].model_dump(by_alias=True)
        fi_record["linkRefNumber"] = account_state.get("linkRefNumber")
        fi_record["maskedAccNumber"] = account_state.get("maskedAccNumber")
        return {
            "account": {
                "linkedAccRef": account_state.get("linkRefNumber"),
                "maskedAccNumber": account_state.get("maskedAccNumber"),
                "type": fi_record.get("FIType", "DEPOSIT"),
                "version": "1.1",
                "profile": fi_record.get("Profile"),
                "summary": fi_record.get("Profile", {}).get("Summary"),
                "transactions": fi_record.get("Transactions", []),
            }
        }

    def fetch_data_session(self, user: CurrentUser, session_id: str) -> SessionFetchResponse:
        session = self._store.get_data_session(user.uid, session_id)
        if session is None:
            raise HTTPException(status_code=404, detail="Data session not found.")

        consent = self._store.get_consent(user.uid, session.get("consentId"))
        if consent is None:
            raise HTTPException(status_code=404, detail="Consent not found for data session.")

        accounts = session.get("accounts", [])
        transitioned = False
        for account in accounts:
            if account.get("FIStatus") == "PENDING":
                account["FIStatus"] = account.get("plannedStatus", "PENDING")
                account["description"] = (
                    "Data prepared by FIP"
                    if account["FIStatus"] == "READY"
                    else "FIP could not complete request"
                )
                transitioned = True

        if transitioned:
            for account in accounts:
                if account.get("FIStatus") == "PENDING":
                    account["FIStatus"] = "TIMEOUT"
                    account["description"] = "FIP response timed out"

            new_combined = self._combined_session_status([account["FIStatus"] for account in accounts])
            session = self._store.update_data_session(
                user.uid,
                session_id,
                {
                    "accounts": accounts,
                    "status": new_combined,
                },
            ) or session

            webhook_payload = {
                "data": {
                    "status": session.get("status", "PENDING"),
                    "fips": [
                        {
                            "fipID": account["fipId"],
                            "accounts": [
                                {
                                    "linkRefNumber": account["linkRefNumber"],
                                    "description": account["description"],
                                    "FIStatus": account["FIStatus"],
                                }
                            ],
                        }
                        for account in accounts
                    ],
                    "format": session.get("format", "json"),
                },
                "timestamp": self._to_iso(utc_now()),
                "dataSessionId": session_id,
                "success": True,
                "type": "SESSION_STATUS_UPDATE",
                "error": None,
                "consentId": session.get("consentId"),
                "notificationId": self._notification_id(),
            }
            self._emit_webhook(user.uid, webhook_payload, session.get("notificationUrl"))

        grouped: dict[str, list[dict[str, Any]]] = defaultdict(list)
        final_statuses: list[str] = []

        for account in accounts:
            current_status = account.get("FIStatus", "PENDING")
            entry: dict[str, Any] = {
                "linkRefNumber": account.get("linkRefNumber"),
                "maskedAccNumber": account.get("maskedAccNumber"),
                "FIStatus": current_status,
                "description": account.get("description", ""),
            }

            if current_status == "READY":
                entry["data"] = self._mock_fi_data(account)
                entry["FIStatus"] = "DELIVERED"
                account["FIStatus"] = "DELIVERED"
            final_statuses.append(entry["FIStatus"])
            grouped[account.get("fipId", "unknown")].append(entry)

        final_combined = self._combined_session_status(final_statuses)
        self._store.update_data_session(
            user.uid,
            session_id,
            {
                "accounts": accounts,
                "status": final_combined,
                "lastFetchedAt": utc_now(),
            },
        )

        response_payload = {
            "id": session_id,
            "status": final_combined,
            "format": session.get("format", "json"),
            "consentId": session.get("consentId"),
            "traceId": session.get("traceId", self._trace_id()),
            "fips": [
                {
                    "fipID": fip_id,
                    "accounts": items,
                }
                for fip_id, items in grouped.items()
            ],
        }

        return SessionFetchResponse.model_validate(response_payload)

    def get_last_fetch_status(self, user: CurrentUser, consent_id: str) -> LastFetchStatusResponse:
        rows = self._store.list_data_sessions_by_consent(user.uid, consent_id)
        if not rows:
            raise HTTPException(status_code=404, detail="No data sessions found for consent.")

        latest = rows[0]
        last_fetched = latest.get("lastFetchedAt")
        fips = [account.get("fipId", "") for account in latest.get("accounts", [])]

        payload = {
            "lastFetchedAt": self._to_datetime(last_fetched) if last_fetched else None,
            "dataRange": latest.get("dataRange"),
            "lastFetchedFips": fips,
            "traceId": self._trace_id(),
        }
        return LastFetchStatusResponse.model_validate(payload)

    def get_data_sessions_by_consent(
        self, user: CurrentUser, consent_id: str
    ) -> ConsentDataSessionsResponse:
        rows = self._store.list_data_sessions_by_consent(user.uid, consent_id)
        payload = {
            "consentId": consent_id,
            "dataSessions": [
                {
                    "sessionId": row.get("id"),
                    "status": row.get("status"),
                    "created_at": self._to_datetime(row.get("createdAt")),
                }
                for row in rows
            ],
            "traceId": self._trace_id(),
        }
        return ConsentDataSessionsResponse.model_validate(payload)

    def create_consent_collection(
        self,
        _user: CurrentUser,
        request_body: ConsentCollectionRequest,
        public_base_url: str,
    ) -> ConsentCollectionResponse:
        if not request_body.mandatory_consents:
            raise HTTPException(
                status_code=400,
                detail="At least one mandatory consent is required.",
            )

        consent_collection_id = str(uuid4())
        return ConsentCollectionResponse.model_validate(
            {
                "consentCollectionId": consent_collection_id,
                "url": f"{public_base_url.rstrip('/')}/v2/consents/webview/{consent_collection_id}",
                "txnid": str(uuid4()),
                "traceId": self._trace_id(),
            }
        )

    def list_webhook_events(self, user: CurrentUser, limit: int) -> list[dict[str, Any]]:
        safe_limit = max(1, min(limit, 100))
        rows = self._store.list_webhook_events(user.uid, safe_limit)
        return rows

    def get_user_profile(self, user: CurrentUser) -> dict[str, Any]:
        self._store.upsert_user(user.uid, user.email, user.phone_number)
        profile = self._store.get_user_profile(user.uid)
        return {
            "uid": user.uid,
            "email": user.email,
            "phone_number": user.phone_number,
            "profile": profile,
        }

    def get_mock_aa_data(self, user: CurrentUser) -> dict[str, Any]:
        payload = self._mock_aa_service.generate_mock_payload()
        self._store.create_audit_event(
            {
                "userId": user.uid,
                "eventType": "MOCK_AA_DATA_FETCHED",
                "createdAt": utc_now(),
            }
        )
        return payload.model_dump(by_alias=True)

    def analyze_transactions(self, user: CurrentUser, aa_payload: AAMockDataResponse | None) -> dict[str, Any]:
        payload = aa_payload or self._mock_aa_service.generate_mock_payload()
        analysis = self._analysis_service.analyze(payload)
        generated_at = utc_now()

        run_id = str(uuid4())
        self._store.create_analysis_run(
            {
                "runId": run_id,
                "userId": user.uid,
                "generatedAt": generated_at,
                "scannedTransactionCount": analysis.scanned_transaction_count,
                "totalMonthlyLeakage": float(analysis.total_monthly_leakage),
                "currency": analysis.currency,
                "source": payload.txnid,
                "createdAt": utc_now(),
            }
        )

        detected_rows: list[dict[str, Any]] = []
        for item in analysis.detected_subscriptions:
            previous = self._store.get_detected_subscription(user.uid, item.merchant_code)
            resolved_previous = bool(previous.get("resolved")) if previous else False
            row = {
                "userId": user.uid,
                "merchantCode": item.merchant_code,
                "displayName": item.display_name,
                "sampleNarration": item.sample_narration,
                "threatLevel": item.threat_level,
                "confidenceScore": float(item.confidence_score),
                "occurrenceCount": int(item.occurrence_count),
                "averageAmount": float(item.average_amount),
                "estimatedMonthlyAmount": float(item.estimated_monthly_amount),
                "firstSeen": datetime.combine(item.first_seen, datetime.min.time(), tzinfo=UTC),
                "lastChargedOn": datetime.combine(item.last_charged_on, datetime.min.time(), tzinfo=UTC),
                "reasoning": item.reasoning,
                "resolved": resolved_previous,
                "updatedAt": utc_now(),
            }
            self._store.upsert_detected_subscription(user.uid, item.merchant_code, row)
            detected_rows.append(
                {
                    "merchant_code": item.merchant_code,
                    "display_name": item.display_name,
                    "sample_narration": item.sample_narration,
                    "threat_level": item.threat_level,
                    "confidence_score": float(item.confidence_score),
                    "occurrence_count": int(item.occurrence_count),
                    "average_amount": float(item.average_amount),
                    "estimated_monthly_amount": float(item.estimated_monthly_amount),
                    "first_seen": datetime.combine(
                        item.first_seen,
                        datetime.min.time(),
                        tzinfo=UTC,
                    ).isoformat(),
                    "last_charged_on": datetime.combine(
                        item.last_charged_on,
                        datetime.min.time(),
                        tzinfo=UTC,
                    ).isoformat(),
                    "reasoning": item.reasoning,
                    "resolved": resolved_previous,
                }
            )

        self._store.create_audit_event(
            {
                "userId": user.uid,
                "eventType": "ANALYSIS_COMPLETED",
                "runId": run_id,
                "detectedCount": len(detected_rows),
                "totalMonthlyLeakage": float(analysis.total_monthly_leakage),
                "createdAt": utc_now(),
            }
        )

        detected_rows.sort(
            key=lambda row: float(row.get("estimated_monthly_amount", 0.0)),
            reverse=True,
        )
        return {
            "generated_at": generated_at.isoformat(),
            "scanned_transaction_count": analysis.scanned_transaction_count,
            "detected_subscriptions": detected_rows,
            "total_monthly_leakage": float(
                sum(
                    Decimal(str(row["estimated_monthly_amount"]))
                    for row in detected_rows
                    if not row.get("resolved", False)
                )
            ),
            "currency": analysis.currency,
        }

    def get_latest_analysis(self, user: CurrentUser) -> dict[str, Any] | None:
        latest = self._store.get_latest_analysis_run(user.uid)
        if latest is None:
            return None

        rows = self._store.list_detected_subscriptions(user.uid)
        detected = [
            {
                "merchant_code": row.get("merchantCode"),
                "display_name": row.get("displayName"),
                "sample_narration": row.get("sampleNarration"),
                "threat_level": row.get("threatLevel"),
                "confidence_score": float(row.get("confidenceScore", 0.0)),
                "occurrence_count": int(row.get("occurrenceCount", 0)),
                "average_amount": float(row.get("averageAmount", 0.0)),
                "estimated_monthly_amount": float(row.get("estimatedMonthlyAmount", 0.0)),
                "first_seen": self._to_iso(row.get("firstSeen")),
                "last_charged_on": self._to_iso(row.get("lastChargedOn")),
                "reasoning": row.get("reasoning", ""),
                "resolved": bool(row.get("resolved", False)),
            }
            for row in rows
        ]

        active_total = sum(
            row["estimated_monthly_amount"] for row in detected if not row["resolved"]
        )

        return {
            "generated_at": self._to_iso(latest.get("generatedAt")),
            "scanned_transaction_count": int(latest.get("scannedTransactionCount", 0)),
            "detected_subscriptions": detected,
            "total_monthly_leakage": float(active_total),
            "currency": latest.get("currency", "INR"),
        }

    def revoke_mandate(self, user: CurrentUser, merchant_code: str) -> dict[str, Any]:
        updated = self._store.mark_subscription_resolved(user.uid, merchant_code)
        if updated is None:
            raise HTTPException(status_code=404, detail="Subscription not found for this user.")

        monthly_amount = float(updated.get("estimatedMonthlyAmount", 0.0))
        annual_savings = round(monthly_amount * 12, 2)
        self._store.create_revoke_action(
            {
                "userId": user.uid,
                "merchantCode": merchant_code,
                "monthlyAmount": monthly_amount,
                "annualSavings": annual_savings,
                "status": "COMPLETED",
                "createdAt": utc_now(),
            }
        )

        self._store.create_audit_event(
            {
                "userId": user.uid,
                "eventType": "MANDATE_REVOKED",
                "merchantCode": merchant_code,
                "createdAt": utc_now(),
            }
        )

        return {
            "status": "resolved",
            "merchant_code": merchant_code,
            "annual_savings": annual_savings,
            "message": "Mandate revoked in simulator.",
        }

    @staticmethod
    def _consent_to_response(consent: dict[str, Any]) -> ConsentResponse:
        payload = {
            "id": consent.get("id"),
            "url": consent.get("url"),
            "status": consent.get("status"),
            "detail": consent.get("detail", {}),
            "context": consent.get("context", []),
            "accountsLinked": consent.get("accountsLinked", []),
            "tags": consent.get("tags", []),
            "traceId": consent.get("traceId") or str(uuid4()),
        }
        return ConsentResponse.model_validate(payload)
