from __future__ import annotations

from datetime import datetime, timedelta, timezone


def _data_range() -> dict[str, str]:
    now = datetime.now(timezone.utc)
    return {
        "from": (now - timedelta(days=90)).isoformat(),
        "to": now.isoformat(),
    }


def test_v2_consent_session_lifecycle(client):
    availability = client.post(
        "/v2/account-availability",
        json={"mobileNumber": "9999999999"},
    )
    assert availability.status_code == 200
    linked_banks = availability.json()["linkedBanks"]
    assert linked_banks
    selected_account = linked_banks[0]["accounts"][0]

    selection = client.post(
        "/v2/account-selection",
        json={
            "mobileNumber": "9999999999",
            "selectedLinkRefNumbers": [selected_account["linkRefNumber"]],
        },
    )
    assert selection.status_code == 200

    consent_create = client.post(
        "/v2/consents",
        json={
            "consentDuration": {"unit": "MONTH", "value": "4"},
            "vua": "9999999999@onemoney",
            "fiTypes": ["DEPOSIT"],
            "consentTypes": ["PROFILE", "SUMMARY", "TRANSACTIONS"],
            "dataRange": _data_range(),
            "context": [{"key": "fipId", "value": selected_account["fipId"]}],
            "additionalParams": {
                "tags": ["hackathon", "revamp"],
                "notificationUrl": "https://example.invalid/webhook",
            },
        },
    )
    assert consent_create.status_code == 200
    consent = consent_create.json()
    assert consent["status"] == "PENDING"
    assert "/v2/consents/webview/" in consent["url"]
    assert len(consent["accountsLinked"]) == 1
    assert (
        consent["accountsLinked"][0]["linkRefNumber"]
        == selected_account["linkRefNumber"]
    )

    consent_id = consent["id"]

    approved = client.post(
        f"/v2/simulator/consents/{consent_id}/action",
        json={"action": "approve"},
    )
    assert approved.status_code == 200
    assert approved.json()["status"] == "ACTIVE"

    session_create = client.post(
        "/v2/sessions",
        json={
            "consentId": consent_id,
            "dataRange": _data_range(),
            "format": "json",
        },
    )
    assert session_create.status_code == 200
    session = session_create.json()
    assert session["status"] == "PENDING"

    session_id = session["id"]

    fetched = client.get(f"/v2/sessions/{session_id}")
    assert fetched.status_code == 200
    fetched_json = fetched.json()
    assert fetched_json["status"] in {"PARTIAL", "COMPLETED", "FAILED"}
    assert isinstance(fetched_json["fips"], list)
    assert fetched_json["fips"], "Expected at least one FIP response"

    sessions_for_consent = client.get(f"/v2/consents/{consent_id}/data-sessions")
    assert sessions_for_consent.status_code == 200
    sessions_json = sessions_for_consent.json()
    assert sessions_json["consentId"] == consent_id
    assert len(sessions_json["dataSessions"]) >= 1

    last_fetch = client.get(f"/v2/consents/{consent_id}/fetch/status")
    assert last_fetch.status_code == 200

    revoke = client.post(f"/v2/consents/{consent_id}/revoke")
    assert revoke.status_code == 200
    assert revoke.json()["status"] == "REVOKED"
