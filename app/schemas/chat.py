from __future__ import annotations

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str = Field(min_length=1, max_length=4000)


class ChatAssistRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)
    history: list[ChatMessage] = Field(default_factory=list)


class GroundingSource(BaseModel):
    title: str
    url: str


class ChatAssistResponse(BaseModel):
    reply: str
    grounded: bool
    sources: list[GroundingSource] = Field(default_factory=list)
    suggested_actions: list[str] = Field(default_factory=list, alias="suggestedActions")
    trace_id: str = Field(alias="traceId")


class ManualUploadRequest(BaseModel):
    file_name: str = Field(default="manual-entry.txt", alias="fileName")
    content: str = Field(min_length=1, max_length=200000)
    upload_method: Literal["paste", "file"] = Field(default="paste", alias="uploadMethod")


class ManualUploadResponse(BaseModel):
    upload_id: str = Field(alias="uploadId")
    status: str
    records_parsed: int = Field(alias="recordsParsed")
    estimated_subscriptions: int = Field(alias="estimatedSubscriptions")
    next_steps: list[str] = Field(default_factory=list, alias="nextSteps")
    trace_id: str = Field(alias="traceId")


class SupportTicketRequest(BaseModel):
    title: str = Field(min_length=4, max_length=140)
    description: str = Field(min_length=8, max_length=4000)
    category: str = Field(default="BANKING_HELP")
    priority: Literal["LOW", "MEDIUM", "HIGH"] = Field(default="MEDIUM")


class SupportTicketResponse(BaseModel):
    ticket_id: str = Field(alias="ticketId")
    status: str
    message: str
    created_at: datetime = Field(alias="createdAt")
    trace_id: str = Field(alias="traceId")


class ServiceRequestCreateRequest(BaseModel):
    request_type: str = Field(alias="requestType", min_length=3, max_length=120)
    details: str = Field(min_length=8, max_length=4000)
    account_link_ref_number: str | None = Field(default=None, alias="accountLinkRefNumber")


class ServiceRequestCreateResponse(BaseModel):
    request_id: str = Field(alias="requestId")
    status: str
    message: str
    created_at: datetime = Field(alias="createdAt")
    trace_id: str = Field(alias="traceId")
