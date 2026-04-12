from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field


class AAV2BaseModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class ContextEntry(AAV2BaseModel):
    key: str
    value: str


class TimeWindow(AAV2BaseModel):
    unit: str
    value: str


class DateRangeTime(AAV2BaseModel):
    from_date: datetime = Field(alias="from")
    to_date: datetime = Field(alias="to")


class AdditionalParams(AAV2BaseModel):
    tags: list[str] = Field(default_factory=list)
    notification_url: str | None = Field(default=None, alias="notificationUrl")


class CreateConsentRequest(AAV2BaseModel):
    consent_duration: TimeWindow | None = Field(default=None, alias="consentDuration")
    consent_mode: Literal["VIEW", "STORE", "QUERY", "STREAM"] = Field(
        default="VIEW", alias="consentMode"
    )
    fetch_type: Literal["ONETIME", "PERIODIC"] = Field(default="ONETIME", alias="fetchType")
    consent_types: list[str] = Field(
        default_factory=lambda: ["PROFILE", "SUMMARY", "TRANSACTIONS"],
        alias="consentTypes",
    )
    fi_types: list[str] = Field(default_factory=lambda: ["DEPOSIT"], alias="fiTypes")
    vua: str
    purpose: dict[str, Any] | None = None
    data_range: DateRangeTime = Field(alias="dataRange")
    data_life: TimeWindow | None = Field(default=None, alias="dataLife")
    frequency: TimeWindow | None = None
    redirect_url: str | None = Field(default=None, alias="redirectUrl")
    context: list[ContextEntry] = Field(default_factory=list)
    additional_params: AdditionalParams | None = Field(default=None, alias="additionalParams")


class LinkedAccount(AAV2BaseModel):
    masked_acc_number: str = Field(alias="maskedAccNumber")
    acc_type: str = Field(alias="accType")
    fip_id: str = Field(alias="fipId")
    fi_type: str = Field(alias="fiType")
    link_ref_number: str = Field(alias="linkRefNumber")


class ConsentResponse(AAV2BaseModel):
    id: str
    url: str
    status: str
    detail: dict[str, Any]
    context: list[ContextEntry]
    accounts_linked: list[LinkedAccount] = Field(alias="accountsLinked")
    tags: list[str] = Field(default_factory=list)
    trace_id: str = Field(alias="traceId")


class RevokeConsentResponse(AAV2BaseModel):
    status: str
    trace_id: str = Field(alias="traceId")


class LastFetchStatusResponse(AAV2BaseModel):
    last_fetched_at: datetime | None = Field(alias="lastFetchedAt")
    data_range: DateRangeTime | None = Field(alias="dataRange")
    last_fetched_fips: list[str] = Field(alias="lastFetchedFips")
    trace_id: str = Field(alias="traceId")


class ConsentSessionSummary(AAV2BaseModel):
    session_id: str = Field(alias="sessionId")
    status: str
    created_at: datetime = Field(alias="created_at")


class ConsentDataSessionsResponse(AAV2BaseModel):
    consent_id: str = Field(alias="consentId")
    data_sessions: list[ConsentSessionSummary] = Field(alias="dataSessions")
    trace_id: str = Field(alias="traceId")


class ConsentCollectionRequest(AAV2BaseModel):
    optional_consents: list[str] = Field(default_factory=list, alias="optionalConsents")
    mandatory_consents: list[str] = Field(default_factory=list, alias="mandatoryConsents")


class ConsentCollectionResponse(AAV2BaseModel):
    consent_collection_id: str = Field(alias="consentCollectionId")
    url: str
    txnid: str
    trace_id: str = Field(alias="traceId")


class CreateDataSessionRequest(AAV2BaseModel):
    consent_id: str = Field(alias="consentId")
    data_range: DateRangeTime = Field(alias="dataRange")
    format: Literal["json", "xml"] = "json"


class DataSessionCreateResponse(AAV2BaseModel):
    id: str
    status: str
    format: str
    consent_id: str = Field(alias="consentId")
    data_range: DateRangeTime = Field(alias="dataRange")
    trace_id: str = Field(alias="traceId")


class SessionAccountData(AAV2BaseModel):
    link_ref_number: str = Field(alias="linkRefNumber")
    masked_acc_number: str = Field(alias="maskedAccNumber")
    fi_status: str = Field(alias="FIStatus")
    description: str
    data: dict[str, Any] | None = None


class SessionFipData(AAV2BaseModel):
    fip_id: str = Field(alias="fipID")
    accounts: list[SessionAccountData]


class SessionFetchResponse(AAV2BaseModel):
    id: str
    status: str
    format: str
    consent_id: str = Field(alias="consentId")
    fips: list[SessionFipData]
    trace_id: str = Field(alias="traceId")


class AccountAvailabilityRequest(AAV2BaseModel):
    mobile_number: str = Field(alias="mobileNumber")


class AccountAvailabilityItem(AAV2BaseModel):
    aa: str
    vua: str
    status: bool


class AccountAvailabilityResponse(AAV2BaseModel):
    accounts: list[AccountAvailabilityItem]
    trace_id: str = Field(alias="traceId")


class FipInfo(AAV2BaseModel):
    name: str
    fip_id: str = Field(alias="fipId")
    fi_types: list[str] = Field(alias="fiTypes")
    institution_type: str = Field(alias="institutionType")
    status: str
    consent_conversion_rate: float = Field(alias="consentConversionRate")
    data_fetch_success_rate: float = Field(alias="dataFetchSuccessRate")
    aa_wise_success_rate: list[dict[str, Any]] = Field(alias="aaWiseSuccessRate")
    aa_wise_health_metrics: dict[str, list[dict[str, Any]]] | None = Field(
        default=None, alias="aaWiseHealthMetrics"
    )


class FipListResponse(AAV2BaseModel):
    data: list[FipInfo]
    trace_id: str = Field(alias="traceId")


class SimulateConsentActionRequest(AAV2BaseModel):
    action: Literal["approve", "reject", "pause", "resume"]


class GenericStatusResponse(AAV2BaseModel):
    status: str
    message: str
    trace_id: str = Field(alias="traceId")
