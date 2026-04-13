from __future__ import annotations


def test_app_compat_analyze_latest_revoke_flow(client):
    me = client.get("/api/me")
    assert me.status_code == 200
    assert me.json()["uid"] == "test-user"

    mock_payload = client.get("/api/mock-aa-data")
    assert mock_payload.status_code == 200
    assert "FI" in mock_payload.json()

    analyzed = client.post("/api/analyze-transactions", json={})
    assert analyzed.status_code == 200
    analyzed_json = analyzed.json()
    assert analyzed_json["scanned_transaction_count"] > 0
    assert analyzed_json["detected_subscriptions"], "Expected detected subscriptions"

    analyzed_repeat = client.post("/api/analyze-transactions", json={})
    assert analyzed_repeat.status_code == 200
    analyzed_repeat_json = analyzed_repeat.json()

    first_run_codes = [item["merchant_code"] for item in analyzed_json["detected_subscriptions"]]
    second_run_codes = [
        item["merchant_code"] for item in analyzed_repeat_json["detected_subscriptions"]
    ]
    assert second_run_codes == first_run_codes
    assert (
        analyzed_repeat_json["total_monthly_leakage"]
        == analyzed_json["total_monthly_leakage"]
    )

    first_merchant = analyzed_json["detected_subscriptions"][0]["merchant_code"]

    latest = client.get("/api/analysis/latest")
    assert latest.status_code == 200
    latest_json = latest.json()
    assert latest_json["detected_subscriptions"]

    revoke = client.post("/api/revoke-mandate", json={"merchant_code": first_merchant})
    assert revoke.status_code == 200
    assert revoke.json()["status"] == "resolved"

    latest_after_revoke = client.get("/api/analysis/latest")
    assert latest_after_revoke.status_code == 200
    after_json = latest_after_revoke.json()
    matching = [
        row for row in after_json["detected_subscriptions"] if row["merchant_code"] == first_merchant
    ]
    assert matching and matching[0]["resolved"] is True
