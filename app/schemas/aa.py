from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class AABaseModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class FIDataRange(AABaseModel):
    from_date: date = Field(alias="from")
    to_date: date = Field(alias="to")


class Consent(AABaseModel):
    id: str
    status: Literal["ACTIVE", "PAUSED", "REVOKED"] = "ACTIVE"
    fi_data_range: FIDataRange = Field(alias="FIDataRange")


class Holder(AABaseModel):
    name: str
    mobile: str
    email: str


class AccountSummary(AABaseModel):
    current_balance: Decimal = Field(alias="currentBalance")
    average_monthly_debit: Decimal = Field(alias="averageMonthlyDebit")
    average_monthly_credit: Decimal = Field(alias="averageMonthlyCredit")


class Profile(AABaseModel):
    holders: list[Holder] = Field(alias="Holders")
    summary: AccountSummary = Field(alias="Summary")


class Transaction(AABaseModel):
    txn_id: str = Field(alias="txnId")
    value_date: date = Field(alias="valueDate")
    narration: str
    amount: Decimal = Field(gt=0)
    currency: str = "INR"
    txn_type: Literal["DEBIT", "CREDIT"] = Field(alias="type")
    mode: str
    category: str
    status: Literal["SUCCESS", "FAILED", "REVERSED"] = "SUCCESS"


class FinancialInformation(AABaseModel):
    fi_type: Literal["DEPOSIT"] = Field(alias="FIType")
    fip_id: str = Field(alias="FIPID")
    link_ref_number: str = Field(alias="linkRefNumber")
    masked_acc_number: str = Field(alias="maskedAccNumber")
    profile: Profile = Field(alias="Profile")
    transactions: list[Transaction] = Field(alias="Transactions")


class AAMockDataResponse(AABaseModel):
    ver: str = "1.1.3"
    timestamp: datetime
    txnid: str
    consent: Consent = Field(alias="Consent")
    fi: list[FinancialInformation] = Field(alias="FI")
