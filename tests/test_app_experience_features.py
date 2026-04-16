from __future__ import annotations


def test_manual_upload_chat_and_support_actions(client):
    upload = client.post(
        "/api/manual-upload",
        json={
            "fileName": "statement.txt",
            "uploadMethod": "paste",
            "content": "2026-04-01 NETFLIX 649\n2026-04-02 UPI GROCERY 220\n2026-04-03 SPOTIFY 119",
        },
    )
    assert upload.status_code == 200
    upload_json = upload.json()
    assert upload_json["uploadId"]
    assert upload_json["recordsParsed"] == 3
    assert upload_json["estimatedSubscriptions"] >= 1

    chat = client.post(
        "/api/chat/assist",
        json={
            "message": "How can I stop a recurring debit mandate?",
            "history": [
                {
                    "role": "user",
                    "content": "I keep getting monthly debits",
                }
            ],
        },
    )
    assert chat.status_code == 200
    chat_json = chat.json()
    assert chat_json["reply"]
    assert isinstance(chat_json["suggestedActions"], list)

    ticket = client.post(
        "/api/chat/tickets",
        json={
            "title": "Recurring debit issue",
            "description": "Please help me investigate unauthorized recurring deductions.",
            "category": "BANKING_HELP",
            "priority": "HIGH",
        },
    )
    assert ticket.status_code == 200
    ticket_json = ticket.json()
    assert ticket_json["ticketId"].startswith("TKT-")
    assert ticket_json["status"] == "OPEN"

    request = client.post(
        "/api/chat/requests",
        json={
            "requestType": "MANDATE_REVOKE",
            "details": "Revoke merchant mandate and block further debit instructions.",
            "accountLinkRefNumber": "LNKTEST001",
        },
    )
    assert request.status_code == 200
    request_json = request.json()
    assert request_json["requestId"].startswith("REQ-")
    assert request_json["status"] == "SUBMITTED"


def test_chat_reads_leakage_auditor_subscriptions(client):
    analyze = client.post("/api/analyze-transactions", json={})
    assert analyze.status_code == 200
    analyze_json = analyze.json()
    assert analyze_json["detected_subscriptions"]
    top = analyze_json["detected_subscriptions"][0]

    chat = client.post(
        "/api/chat/assist",
        json={
            "message": "what the most expensive recurring plan i have right now",
            "history": [],
        },
    )

    assert chat.status_code == 200
    chat_json = chat.json()
    reply = chat_json["reply"].lower()
    assert str(top["display_name"]).lower() in reply
    assert "do not have direct access" not in reply
