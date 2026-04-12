from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.aa import AAMockDataResponse


ThreatLevel = Literal["LOW", "MEDIUM", "HIGH"]


class DetectedSubscription(BaseModel):
    merchant_code: str
    display_name: str
    sample_narration: str
    threat_level: ThreatLevel
    confidence_score: float = Field(ge=0.0, le=1.0)
    occurrence_count: int = Field(ge=1)
    average_amount: Decimal = Field(gt=0)
    estimated_monthly_amount: Decimal = Field(gt=0)
    first_seen: date
    last_charged_on: date
    reasoning: str
    resolved: bool = False


class AnalyzeTransactionsResponse(BaseModel):
    generated_at: datetime
    scanned_transaction_count: int = Field(ge=0)
    detected_subscriptions: list[DetectedSubscription]
    total_monthly_leakage: Decimal = Field(ge=0)
    currency: str = "INR"


class AnalyzeTransactionsRequest(BaseModel):
    aa_payload: AAMockDataResponse | None = None
