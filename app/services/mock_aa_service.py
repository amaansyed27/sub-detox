from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
import hashlib

from app.schemas.aa import (
    AAMockDataResponse,
    AccountSummary,
    Consent,
    FIDataRange,
    FinancialInformation,
    Holder,
    Profile,
    Transaction,
)


class MockAAService:
    """Generates realistic, nested Account Aggregator style mock transaction data."""

    def generate_mock_payload(
        self,
        seed_key: str = "default",
        selected_account: dict[str, str] | None = None,
        mobile_number: str | None = None,
    ) -> AAMockDataResponse:
        normalized_seed = seed_key.strip() or "default"
        seed_digest = hashlib.sha256(normalized_seed.encode("utf-8")).hexdigest().upper()
        transactions = self._build_transactions(normalized_seed)

        account_context = selected_account or {}
        link_ref_number = account_context.get("linkRefNumber") or f"LNK-{seed_digest[28:38]}"
        masked_acc_number = account_context.get("maskedAccNumber") or (
            f"XXXXXX{int(seed_digest[38:42], 16) % 10000:04d}"
        )
        fip_id = account_context.get("fipId") or "FIP-ICIC-IND-001"
        holder_mobile = mobile_number or "+919812345678"

        return AAMockDataResponse(
            timestamp=datetime.now(timezone.utc),
            txnid=f"TXN-{seed_digest[:16]}",
            consent=Consent(
                id=f"CONSENT-{seed_digest[16:28]}",
                status="ACTIVE",
                fi_data_range=FIDataRange(
                    from_date=date.today() - timedelta(days=90),
                    to_date=date.today(),
                ),
            ),
            fi=[
                FinancialInformation(
                    fi_type="DEPOSIT",
                    fip_id=fip_id,
                    link_ref_number=link_ref_number,
                    masked_acc_number=masked_acc_number,
                    profile=Profile(
                        holders=[
                            Holder(
                                name="Amaan Sharma",
                                mobile=holder_mobile,
                                email="amaan.sharma@example.com",
                            )
                        ],
                        summary=self._build_summary(transactions),
                    ),
                    transactions=transactions,
                )
            ],
        )

    def _build_transactions(self, seed_key: str) -> list[Transaction]:
        today = date.today()
        serial = 1
        transactions: list[Transaction] = []

        def add_transaction(
            days_ago: int,
            narration: str,
            amount: Decimal,
            txn_type: str,
            mode: str,
            category: str,
        ) -> None:
            nonlocal serial
            transactions.append(
                Transaction(
                    txn_id=f"AA-TXN-{today.strftime('%Y%m')}-{serial:04d}",
                    value_date=today - timedelta(days=days_ago),
                    narration=narration,
                    amount=self._money(amount),
                    txn_type=txn_type,
                    mode=mode,
                    category=category,
                )
            )
            serial += 1

        gym_amount = self._with_variance(Decimal("1499.00"), f"{seed_key}:gym", Decimal("40.00"))
        for days_ago in (8, 38, 68):
            add_transaction(
                days_ago,
                f"GYMCULT-AUTOPAY {gym_amount}",
                gym_amount,
                "DEBIT",
                "UPI_AUTOPAY",
                "SUBSCRIPTION",
            )

        vas_amount = self._with_variance(Decimal("49.00"), f"{seed_key}:vas", Decimal("5.00"))
        for days_ago in (6, 36, 66):
            add_transaction(
                days_ago,
                f"VIL-VAS-HELLOTUNE {vas_amount}",
                vas_amount,
                "DEBIT",
                "AUTO_DEBIT",
                "TELECOM_VAS",
            )

        shield_amount = self._with_variance(
            Decimal("199.00"),
            f"{seed_key}:shield",
            Decimal("12.00"),
        )
        for days_ago in (4, 34, 64):
            add_transaction(
                days_ago,
                f"CREDIT-SHIELD {shield_amount}",
                shield_amount,
                "DEBIT",
                "AUTO_DEBIT",
                "INSURANCE_ADDON",
            )

        netflix_amount = self._with_variance(
            Decimal("649.00"),
            f"{seed_key}:netflix",
            Decimal("20.00"),
        )
        for days_ago in (10, 40, 70):
            add_transaction(
                days_ago,
                f"NETFLIX-SUBSCRIPTION {netflix_amount}",
                netflix_amount,
                "DEBIT",
                "CARD_ECOM",
                "SUBSCRIPTION",
            )

        salary_amount = self._with_variance(
            Decimal("95000.00"),
            f"{seed_key}:salary",
            Decimal("2200.00"),
        )
        for days_ago in (12, 42, 72):
            add_transaction(
                days_ago,
                "ACME CORP SALARY CREDIT",
                salary_amount,
                "CREDIT",
                "NEFT",
                "SALARY",
            )

        for index, days_ago in enumerate((1, 14, 27, 46, 61, 79), start=1):
            amount = self._with_variance(
                Decimal("330.00"),
                f"{seed_key}:zomato:{index}",
                Decimal("95.00"),
            )
            add_transaction(
                days_ago,
                "ZOMATO ORDER",
                amount,
                "DEBIT",
                "UPI",
                "FOOD",
            )

        for index, days_ago in enumerate((3, 18, 33, 52, 74), start=1):
            amount = self._with_variance(
                Decimal("245.00"),
                f"{seed_key}:uber:{index}",
                Decimal("70.00"),
            )
            add_transaction(
                days_ago,
                "UBER TRIP",
                amount,
                "DEBIT",
                "UPI",
                "TRANSPORT",
            )

        for index, days_ago in enumerate((5, 24, 49, 83), start=1):
            amount = self._with_variance(
                Decimal("2860.00"),
                f"{seed_key}:groceries:{index}",
                Decimal("650.00"),
            )
            add_transaction(
                days_ago,
                "BIGBAZAAR GROCERIES",
                amount,
                "DEBIT",
                "UPI",
                "GROCERIES",
            )

        for index, days_ago in enumerate((21, 54, 86), start=1):
            amount = self._with_variance(
                Decimal("1385.00"),
                f"{seed_key}:utilities:{index}",
                Decimal("120.00"),
            )
            add_transaction(
                days_ago,
                "BESCOM ELECTRICITY BILL",
                amount,
                "DEBIT",
                "UPI",
                "UTILITIES",
            )

        transactions.sort(key=lambda item: item.value_date, reverse=True)
        return transactions

    @staticmethod
    def _hash_ratio(value: str) -> Decimal:
        digest = hashlib.sha256(value.encode("utf-8")).hexdigest()
        numerator = Decimal(int(digest[:12], 16))
        denominator = Decimal(int("FFFFFFFFFFFF", 16))
        return numerator / denominator

    def _with_variance(self, base: Decimal, seed: str, max_delta: Decimal) -> Decimal:
        ratio = self._hash_ratio(seed)
        delta = (ratio - Decimal("0.5")) * Decimal("2") * max_delta
        return self._money(base + delta)

    def _build_summary(self, transactions: list[Transaction]) -> AccountSummary:
        debit_total = sum(
            (transaction.amount for transaction in transactions if transaction.txn_type == "DEBIT"),
            start=Decimal("0.00"),
        )
        credit_total = sum(
            (transaction.amount for transaction in transactions if transaction.txn_type == "CREDIT"),
            start=Decimal("0.00"),
        )

        average_monthly_debit = self._money(debit_total / Decimal("3"))
        average_monthly_credit = self._money(credit_total / Decimal("3"))
        current_balance = self._money(Decimal("125000.00") + credit_total - debit_total)

        return AccountSummary(
            current_balance=current_balance,
            average_monthly_debit=average_monthly_debit,
            average_monthly_credit=average_monthly_credit,
        )

    @staticmethod
    def _money(amount: Decimal) -> Decimal:
        return amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
