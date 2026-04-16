from __future__ import annotations

from app.services.gemini_analysis_service import GeminiAnalysisService


def test_parse_reasoning_map_accepts_array_payload() -> None:
    payload = """
[
  {
    "merchant_code": "NETFLIX",
    "reasoning": "Monthly OTT charge that is easy to miss among routine UPI and card spends."
  }
]
"""

    result = GeminiAnalysisService._parse_reasoning_map(payload)

    assert result == {
        "NETFLIX": "Monthly OTT charge that is easy to miss among routine UPI and card spends."
    }


def test_parse_reasoning_map_accepts_camel_case_items() -> None:
    payload = """
{
  "items": [
    {
      "merchantCode": "AMAZONPRIME",
      "reason": "Recurring annual membership can feel one-time and be forgotten in monthly budgeting."
    }
  ]
}
"""

    result = GeminiAnalysisService._parse_reasoning_map(payload)

    assert result == {
        "AMAZONPRIME": "Recurring annual membership can feel one-time and be forgotten in monthly budgeting."
    }
