from collections import defaultdict
from datetime import datetime, timezone
from decimal import Decimal, ROUND_HALF_UP
import re
from typing import Any

from app.schemas.aa import AAMockDataResponse, Transaction
from app.schemas.analysis import AnalyzeTransactionsResponse, DetectedSubscription


class SubscriptionAnalysisService:
    """Mock NLP plus rules engine to isolate recurring subscription leakage."""

    def __init__(self) -> None:
        self.subscription_rules: tuple[dict[str, Any], ...] = (
            {
                "code": "GYMCULT_AUTOPAY",
                "display_name": "Gymcult AutoPay",
                "keywords": ("GYMCULT", "AUTOPAY"),
                "threat_level": "MEDIUM",
                "reasoning": "AutoPay fitness membership detected as recurring debit.",
            },
            {
                "code": "VIL_VAS_HELLOTUNE",
                "display_name": "VIL HelloTune VAS",
                "keywords": ("VIL", "VAS", "HELLOTUNE"),
                "threat_level": "HIGH",
                "reasoning": "Obscure telecom VAS pattern indicates silent recurring leakage.",
            },
            {
                "code": "CREDIT_SHIELD",
                "display_name": "Credit Shield Add-On",
                "keywords": ("CREDIT", "SHIELD"),
                "threat_level": "HIGH",
                "reasoning": "Card protection add-on often remains active unnoticed.",
            },
            {
                "code": "NETFLIX_STANDARD",
                "display_name": "Netflix Standard",
                "keywords": ("NETFLIX",),
                "threat_level": "LOW",
                "reasoning": "Known mainstream streaming subscription.",
            },
        )

    def analyze(self, payload: AAMockDataResponse) -> AnalyzeTransactionsResponse:
        all_transactions = [
            transaction
            for fi_record in payload.fi
            for transaction in fi_record.transactions
        ]
        debit_transactions = [
            transaction
            for transaction in all_transactions
            if transaction.txn_type == "DEBIT"
        ]

        grouped_candidates: dict[str, list[Transaction]] = defaultdict(list)
        rule_lookup: dict[str, dict[str, Any]] = {}

        for transaction in debit_transactions:
            matched_rule = self._match_rule(transaction.narration)
            if matched_rule is None:
                continue

            rule_code = str(matched_rule["code"])
            grouped_candidates[rule_code].append(transaction)
            rule_lookup[rule_code] = matched_rule

        detected_subscriptions: list[DetectedSubscription] = []

        for rule_code, transactions in grouped_candidates.items():
            sorted_transactions = sorted(transactions, key=lambda item: item.value_date)

            if not self._is_monthly_recurring(sorted_transactions):
                continue

            rule = rule_lookup[rule_code]
            average_amount = self._money(
                sum((item.amount for item in sorted_transactions), start=Decimal("0.00"))
                / Decimal(str(len(sorted_transactions)))
            )

            first_seen = sorted_transactions[0].value_date
            last_seen = sorted_transactions[-1].value_date
            confidence = self._confidence(len(sorted_transactions))

            detected_subscriptions.append(
                DetectedSubscription(
                    merchant_code=rule_code,
                    display_name=str(rule["display_name"]),
                    sample_narration=sorted_transactions[-1].narration,
                    threat_level=str(rule["threat_level"]),
                    confidence_score=confidence,
                    occurrence_count=len(sorted_transactions),
                    average_amount=average_amount,
                    estimated_monthly_amount=average_amount,
                    first_seen=first_seen,
                    last_charged_on=last_seen,
                    reasoning=(
                        f"{rule['reasoning']} "
                        f"Recurring monthly pattern observed over {len(sorted_transactions)} cycles."
                    ),
                )
            )

        detected_subscriptions.sort(
            key=lambda item: item.estimated_monthly_amount,
            reverse=True,
        )

        total_monthly_leakage = self._money(
            sum(
                (item.estimated_monthly_amount for item in detected_subscriptions),
                start=Decimal("0.00"),
            )
        )

        return AnalyzeTransactionsResponse(
            generated_at=datetime.now(timezone.utc),
            scanned_transaction_count=len(all_transactions),
            detected_subscriptions=detected_subscriptions,
            total_monthly_leakage=total_monthly_leakage,
            currency="INR",
        )

    def _match_rule(self, narration: str) -> dict[str, Any] | None:
        normalized_narration = self._normalize(narration)
        for rule in self.subscription_rules:
            keywords = tuple(str(keyword) for keyword in rule["keywords"])
            if all(keyword in normalized_narration for keyword in keywords):
                return rule
        return None

    @staticmethod
    def _is_monthly_recurring(transactions: list[Transaction]) -> bool:
        if len(transactions) < 2:
            return False

        day_gaps = [
            (transactions[index].value_date - transactions[index - 1].value_date).days
            for index in range(1, len(transactions))
        ]
        return all(25 <= day_gap <= 35 for day_gap in day_gaps)

    @staticmethod
    def _normalize(value: str) -> str:
        return re.sub(r"[^A-Z0-9]+", " ", value.upper()).strip()

    @staticmethod
    def _confidence(occurrence_count: int) -> float:
        if occurrence_count >= 3:
            return 0.95
        if occurrence_count == 2:
            return 0.80
        return 0.65

    @staticmethod
    def _money(amount: Decimal) -> Decimal:
        return amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
