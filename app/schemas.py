from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class OrderCreate(BaseModel):
    customer_name: str = Field(min_length=2, max_length=80)
    email: str = Field(min_length=5, max_length=120)
    finish: Literal["graphite", "silver", "midnight"]
    memory: Literal["16gb", "32gb", "64gb"]
    delivery_speed: Literal["standard", "priority", "concierge"]
    engraving: str | None = Field(default=None, max_length=40)
    quantity: int = Field(default=1, ge=1, le=3)


class OrderPlacementResponse(BaseModel):
    order_id: str
    workflow_id: str
    status: str
    quote: dict[str, object]


class OrderEventResponse(BaseModel):
    step: str
    message: str
    metadata: dict[str, object] = Field(default_factory=dict)
    created_at: str


class OrderDetailResponse(BaseModel):
    order: dict[str, object]
    events: list[OrderEventResponse]

