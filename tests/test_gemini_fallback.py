from __future__ import annotations

from app.dependencies.auth import CurrentUser
from app.services.aa_gateway_service import AAGatewayService
from app.services.analysis_service import SubscriptionAnalysisService
from app.services.datastore import InMemoryDataStore
from app.services.mock_aa_service import MockAAService


class FailingGeminiService:
    def enrich_analysis(self, payload, analysis):  # noqa: ANN001
        raise RuntimeError("simulated gemini failure")


class EnrichingGeminiService:
    def enrich_analysis(self, payload, analysis):  # noqa: ANN001
        first = analysis.detected_subscriptions[0]
        enriched_first = first.model_copy(
            update={"reasoning": "Gemini enrichment: likely silent renewal pattern."}
        )
        enriched = [enriched_first, *analysis.detected_subscriptions[1:]]
        return analysis.model_copy(update={"detected_subscriptions": enriched})


def _user() -> CurrentUser:
    return CurrentUser(
        uid="gemini-test-user",
        email="gemini-test@example.com",
        phone_number="+919999999999",
    )


def test_gemini_failure_falls_back_to_rules_engine() -> None:
    store = InMemoryDataStore()
    gateway = AAGatewayService(
        store=store,
        analysis_service=SubscriptionAnalysisService(),
        mock_aa_service=MockAAService(),
        gemini_analysis_service=FailingGeminiService(),
    )

    result = gateway.analyze_transactions(user=_user(), aa_payload=None)
    assert result["detected_subscriptions"], "Rules engine output should still be returned."
    assert result["analysis_source"] == "RULES_FALLBACK"
    assert result["gemini_error"]

    run = store.get_latest_analysis_run("gemini-test-user")
    assert run is not None
    assert run["analysisSource"] == "RULES_FALLBACK"
    assert run["geminiError"]


def test_gemini_success_marks_enriched_source() -> None:
    store = InMemoryDataStore()
    gateway = AAGatewayService(
        store=store,
        analysis_service=SubscriptionAnalysisService(),
        mock_aa_service=MockAAService(),
        gemini_analysis_service=EnrichingGeminiService(),
    )

    result = gateway.analyze_transactions(user=_user(), aa_payload=None)
    assert result["detected_subscriptions"][0]["reasoning"].startswith("Gemini enrichment")
    assert result["analysis_source"] == "RULES_PLUS_GEMINI"
    assert result["gemini_error"] is None

    run = store.get_latest_analysis_run("gemini-test-user")
    assert run is not None
    assert run["analysisSource"] == "RULES_PLUS_GEMINI"
    assert run["geminiError"] is None
