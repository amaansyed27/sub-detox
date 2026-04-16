from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutureTimeoutError
import json
import re
from typing import Any

from app.schemas.aa import AAMockDataResponse
from app.schemas.analysis import AnalyzeTransactionsResponse, DetectedSubscription


class GeminiAnalysisError(RuntimeError):
    """Raised when Gemini enrichment cannot be completed safely."""


class GeminiAnalysisService:
    def __init__(self, api_key: str, model: str, timeout_seconds: float) -> None:
        if not api_key.strip():
            raise ValueError("Gemini API key is required.")
        self._api_key = api_key.strip()
        self._model = model.strip()
        self._timeout_seconds = timeout_seconds

    def enrich_analysis(
        self,
        payload: AAMockDataResponse,
        analysis: AnalyzeTransactionsResponse,
    ) -> AnalyzeTransactionsResponse:
        if not analysis.detected_subscriptions:
            return analysis

        prompt = self._build_prompt(payload, analysis)
        response_text = self._call_gemini(prompt)
        reasoning_map = self._parse_reasoning_map(response_text)
        if not reasoning_map:
            raise GeminiAnalysisError("Gemini response did not include usable reasoning updates.")

        enriched_subscriptions: list[DetectedSubscription] = []
        for subscription in analysis.detected_subscriptions:
            updated_reasoning = reasoning_map.get(subscription.merchant_code)
            if not updated_reasoning:
                enriched_subscriptions.append(subscription)
                continue
            enriched_subscriptions.append(
                subscription.model_copy(update={"reasoning": updated_reasoning})
            )

        return analysis.model_copy(
            update={"detected_subscriptions": enriched_subscriptions}
        )

    def _call_gemini(self, prompt: str) -> str:
        try:
            from google import genai
        except ImportError as exc:
            raise GeminiAnalysisError(
                "google-genai SDK not installed. Install dependency or disable Gemini enrichment."
            ) from exc

        client = genai.Client(api_key=self._api_key)

        with ThreadPoolExecutor(max_workers=1) as executor:
            future = executor.submit(
                client.models.generate_content,
                model=self._model,
                contents=prompt,
            )
            try:
                response = future.result(timeout=self._timeout_seconds)
            except FutureTimeoutError as exc:
                raise GeminiAnalysisError("Gemini request timed out.") from exc
            except Exception as exc:  # noqa: BLE001
                raise GeminiAnalysisError(f"Gemini request failed: {exc}") from exc

        text = getattr(response, "text", "")
        if not isinstance(text, str) or not text.strip():
            raise GeminiAnalysisError("Gemini returned an empty response.")
        return text.strip()

    def _build_prompt(
        self,
        payload: AAMockDataResponse,
        analysis: AnalyzeTransactionsResponse,
    ) -> str:
        subscriptions = [
            {
                "merchant_code": item.merchant_code,
                "display_name": item.display_name,
                "sample_narration": item.sample_narration,
                "threat_level": item.threat_level,
                "occurrence_count": item.occurrence_count,
                "estimated_monthly_amount": str(item.estimated_monthly_amount),
                "current_reasoning": item.reasoning,
            }
            for item in analysis.detected_subscriptions
        ]

        recent_transactions = [
            {
                "date": transaction.value_date.isoformat(),
                "narration": transaction.narration,
                "amount": str(transaction.amount),
                "type": transaction.txn_type,
                "mode": transaction.mode,
                "category": transaction.category,
            }
            for fi_record in payload.fi
            for transaction in fi_record.transactions[:14]
        ]

        instructions = {
            "task": "Enrich the existing subscription reasoning for Indian fintech users.",
            "constraints": [
                "Keep each reasoning concise: 18 to 30 words.",
                "Do not invent new merchants.",
                "Do not change threat levels or amounts.",
                "Focus on practical user impact and why charges may be overlooked.",
            ],
            "response_format": {
                "items": [
                    {
                        "merchant_code": "string",
                        "reasoning": "string",
                    }
                ]
            },
        }

        return (
            "You are a fintech analyst assistant. Return only valid JSON with no markdown.\n"
            f"Instructions: {json.dumps(instructions, ensure_ascii=True)}\n"
            f"Detected subscriptions: {json.dumps(subscriptions, ensure_ascii=True)}\n"
            f"Recent transactions sample: {json.dumps(recent_transactions, ensure_ascii=True)}"
        )

    @staticmethod
    def _parse_reasoning_map(response_text: str) -> dict[str, str]:
        cleaned = response_text.strip()
        fenced_match = re.search(r"```(?:json)?\s*([\[{][\s\S]*[\]}])\s*```", cleaned)
        if fenced_match:
            cleaned = fenced_match.group(1).strip()

        try:
            payload = json.loads(cleaned)
        except json.JSONDecodeError as exc:
            raise GeminiAnalysisError("Gemini returned non-JSON content.") from exc

        items: list[Any]
        if isinstance(payload, list):
            items = payload
        elif isinstance(payload, dict):
            raw_items = payload.get("items", payload.get("data", []))
            if not isinstance(raw_items, list):
                return {}
            items = raw_items
        else:
            return {}

        output: dict[str, str] = {}
        for item in items:
            if not isinstance(item, dict):
                continue
            merchant_code = item.get("merchant_code") or item.get("merchantCode")
            reasoning = item.get("reasoning") or item.get("reason")
            if not isinstance(merchant_code, str) or not isinstance(reasoning, str):
                continue
            normalized_reasoning = " ".join(reasoning.strip().split())
            if not normalized_reasoning:
                continue
            output[merchant_code.strip()] = normalized_reasoning

        return output
