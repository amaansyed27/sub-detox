from __future__ import annotations


def test_v2_fips_and_account_availability(client):
    fips = client.get("/v2/fips?expanded=true")
    assert fips.status_code == 200
    payload = fips.json()
    assert payload["data"]

    fip_id = payload["data"][0]["fipId"]
    by_id = client.get(f"/v2/fips/{fip_id}")
    assert by_id.status_code == 200
    assert by_id.json()["data"][0]["fipId"] == fip_id

    availability = client.post(
        "/v2/account-availability",
        json={"mobileNumber": "9999999999"},
    )
    assert availability.status_code == 200
    accounts = availability.json()["accounts"]
    assert len(accounts) >= 2
    assert all("vua" in account for account in accounts)
