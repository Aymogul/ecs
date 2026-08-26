from __future__ import annotations

from datetime import timedelta

from temporalio import workflow
from temporalio.common import RetryPolicy

with workflow.unsafe.imports_passed_through():
    from app.activities import (
        capture_payment,
        prepare_shipment,
        reserve_inventory,
        send_concierge_notification,
    )


@workflow.defn
class AsterOrderWorkflow:
    def __init__(self) -> None:
        self._status = "created"

    @workflow.run
    async def run(self, order_id: str) -> dict[str, str]:
        retry_policy = RetryPolicy(
            initial_interval=timedelta(seconds=1),
            backoff_coefficient=2.0,
            maximum_interval=timedelta(seconds=10),
            maximum_attempts=4,
        )

        self._status = "reserving_inventory"
        reservation = await workflow.execute_activity(
            reserve_inventory,
            order_id,
            start_to_close_timeout=timedelta(seconds=5),
            retry_policy=retry_policy,
        )

        self._status = "charging_payment"
        receipt = await workflow.execute_activity(
            capture_payment,
            order_id,
            start_to_close_timeout=timedelta(seconds=5),
            retry_policy=retry_policy,
        )

        self._status = "preparing_shipment"
        shipment = await workflow.execute_activity(
            prepare_shipment,
            order_id,
            start_to_close_timeout=timedelta(seconds=5),
            retry_policy=retry_policy,
        )

        self._status = "sending_confirmation"
        notification = await workflow.execute_activity(
            send_concierge_notification,
            order_id,
            start_to_close_timeout=timedelta(seconds=5),
            retry_policy=retry_policy,
        )

        self._status = "completed"
        return {
            "order_id": order_id,
            "reservation_id": reservation["reservation_id"],
            "receipt_id": receipt["receipt_id"],
            "shipment_id": shipment["shipment_id"],
            "notification_id": notification["notification_id"],
            "status": self._status,
        }

    @workflow.query
    def status(self) -> str:
        return self._status
