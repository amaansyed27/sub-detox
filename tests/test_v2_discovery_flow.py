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
    availability_payload = availability.json()
    accounts = availability_payload["accounts"]
    assert len(accounts) >= 2
    assert all("vua" in account for account in accounts)

    linked_banks = availability_payload["linkedBanks"]
    assert linked_banks
    assert linked_banks[0]["accounts"]

    first_link_ref = linked_banks[0]["accounts"][0]["linkRefNumber"]

    availability_repeat = client.post(
        "/v2/account-availability",
        json={"mobileNumber": "9999999999"},
    )
    assert availability_repeat.status_code == 200
    assert availability_repeat.json()["linkedBanks"] == linked_banks

    selection = client.post(
        "/v2/account-selection",
        json={
            "mobileNumber": "9999999999",
            "selectedLinkRefNumbers": [first_link_ref],
        },
    )
    assert selection.status_code == 200
    selected_accounts = selection.json()["selectedAccounts"]
    assert len(selected_accounts) == 1
    assert selected_accounts[0]["linkRefNumber"] == first_link_ref
