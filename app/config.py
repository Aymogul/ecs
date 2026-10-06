from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "Aster Studio")
    database_url: str = os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://aster:aster@postgres:5432/aster_app",
    )
    temporal_address: str = os.getenv("TEMPORAL_ADDRESS", "temporal:7233")
    temporal_namespace: str = os.getenv("TEMPORAL_NAMESPACE", "default")
    temporal_api_key: str | None = os.getenv("TEMPORAL_API_KEY") or None
    temporal_tls: bool = os.getenv("TEMPORAL_TLS", "false").lower() == "true"
    task_queue: str = os.getenv("TASK_QUEUE", "aster-orders")
    demo_fail_first_payment: bool = os.getenv("DEMO_FAIL_FIRST_PAYMENT", "true").lower() == "true"
    recent_orders_limit: int = int(os.getenv("RECENT_ORDERS_LIMIT", "8"))


settings = Settings()
