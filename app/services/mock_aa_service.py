from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from uuid import uuid4

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

    def generate_mock_payload(self) -> AAMockDataResponse:
        transactions = self._build_transactions()

        return AAMockDataResponse(
            timestamp=datetime.now(timezone.utc),
            txnid=f"TXN-{uuid4().hex[:16].upper()}",
            consent=Consent(
                id=f"CONSENT-{uuid4().hex[:12].upper()}",
                status="ACTIVE",
                fi_data_range=FIDataRange(
                    from_date=date.today() - timedelta(days=90),
                    to_date=date.today(),
                ),
            ),
            fi=[
                FinancialInformation(
                    fi_type="DEPOSIT",
                    fip_id="FIP-ICIC-IND-001",
                    link_ref_number=f"LNK-{uuid4().hex[:10].upper()}",
                    masked_acc_number="XXXXXX4521",
                    profile=Profile(
                        holders=[
                            Holder(
                                name="Amaan Sharma",
                                mobile="+919812345678",
                                email="amaan.sharma@example.com",
                            )
                        ],
                        summary=self._build_summary(transactions),
                    ),
                    transactions=transactions,
                )
            ],
        )

    def _build_transactions(self) -> list[Transaction]:
        today = date.today()
        serial = 1
        transactions: list[Transaction] = []

        def add_transaction(
            days_ago: int,
            narration: str,
            amount: str,
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
                    amount=Decimal(amount),
                    txn_type=txn_type,
                    mode=mode,
                    category=category,
                )
            )
            serial += 1

        # Hidden recurring leaks we want the analysis engine to catch.
        for days_ago in (8, 38, 68):
            add_transaction(
                days_ago,
                "GYMCULT-AUTOPAY 1499.00",
                "1499.00",
                "DEBIT",
                "UPI_AUTOPAY",
                "SUBSCRIPTION",
            )

        for days_ago in (6, 36, 66):
            add_transaction(
                days_ago,
                "VIL-VAS-HELLOTUNE 49.00",
                "49.00",
                "DEBIT",
                "AUTO_DEBIT",
                "TELECOM_VAS",
            )

        for days_ago in (4, 34, 64):
            add_transaction(
                days_ago,
                "CREDIT-SHIELD 199.00",
                "199.00",
                "DEBIT",
                "AUTO_DEBIT",
                "INSURANCE_ADDON",
            )

        # A known, non-obscure subscription to benchmark low-risk detection.
        for days_ago in (10, 40, 70):
            add_transaction(
                days_ago,
                "NETFLIX-SUBSCRIPTION 649.00",
                "649.00",
                "DEBIT",
                "CARD_ECOM",
                "SUBSCRIPTION",
            )

        for days_ago, amount in ((12, "95000.00"), (42, "95000.00"), (72, "95000.00")):
            add_transaction(
                days_ago,
                "ACME CORP SALARY CREDIT",
                amount,
                "CREDIT",
                "NEFT",
                "SALARY",
            )

        for days_ago, amount in (
            (1, "342.00"),
            (14, "287.00"),
            (27, "418.00"),
            (46, "361.00"),
            (61, "299.00"),
            (79, "322.00"),
        ):
            add_transaction(
                days_ago,
                "ZOMATO ORDER",
                amount,
                "DEBIT",
                "UPI",
                "FOOD",
            )

        for days_ago, amount in (
            (3, "221.00"),
            (18, "312.00"),
            (33, "188.00"),
            (52, "274.00"),
            (74, "197.00"),
        ):
            add_transaction(
                days_ago,
                "UBER TRIP",
                amount,
                "DEBIT",
                "UPI",
                "TRANSPORT",
            )

        for days_ago, amount in ((5, "2289.00"), (24, "3411.00"), (49, "2750.00"), (83, "3012.00")):
            add_transaction(
                days_ago,
                "BIGBAZAAR GROCERIES",
                amount,
                "DEBIT",
                "UPI",
                "GROCERIES",
            )

        for days_ago, amount in ((21, "1320.00"), (54, "1459.00"), (86, "1389.00")):
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
