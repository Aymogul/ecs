from __future__ import annotations

import asyncio
import hashlib
import logging
from uuid import uuid4

from temporalio import activity

from app import db
from app.config import settings

logger = logging.getLogger(__name__)


def stable_id(prefix: str, *parts: str) -> str:
    digest = hashlib.sha256(":".join(parts).encode("utf-8")).hexdigest()[:16]
    return f"{prefix}-{digest}"


@activity.defn
async def reserve_inventory(order_id: str) -> dict[str, object]:
    order = db.get_order(order_id)
    if order is None:
        raise RuntimeError(f"missing order {order_id}")

    await asyncio.sleep(0.25)
    reservation_id = stable_id("res", order_id, order["finish"], order["memory"])
    db.update_order(
        order_id,
        status="inventory_reserved",
        workflow_status="reserved",
        reservation_id=reservation_id,
    )
    db.append_event(
        order_id,
        "inventory_reserved",
        "Reserved inventory for the studio build.",
        {"reservation_id": reservation_id, "finish": order["finish"], "memory": order["memory"]},
    )
    logger.info("inventory reserved", extra={"order_id": order_id, "reservation_id": reservation_id})
    return {"reservation_id": reservation_id}


@activity.defn
async def capture_payment(order_id: str) -> dict[str, object]:
    order = db.get_order(order_id)
    if order is None:
        raise RuntimeError(f"missing order {order_id}")

    attempt = activity.info().attempt
    await asyncio.sleep(0.25)

    if settings.demo_fail_first_payment and attempt == 1:
        db.append_event(
            order_id,
            "payment_failed",
            "Simulated card gateway failure on the first attempt.",
            {"attempt": attempt},
        )
        logger.warning("simulated payment failure", extra={"order_id": order_id, "attempt": attempt})
        raise RuntimeError("payment gateway returned HTTP 503")

    receipt_id = stable_id("pay", order_id, order["email"])
    db.update_order(
        order_id,
        status="payment_captured",
        workflow_status="paid",
        receipt_id=receipt_id,
    )
    db.append_event(
        order_id,
        "payment_captured",
        "Captured payment and issued a stable receipt.",
        {"receipt_id": receipt_id, "attempt": attempt},
    )
    return {"receipt_id": receipt_id, "attempt": attempt}


@activity.defn
async def prepare_shipment(order_id: str) -> dict[str, object]:
    order = db.get_order(order_id)
    if order is None:
        raise RuntimeError(f"missing order {order_id}")

    await asyncio.sleep(0.2)
    shipment_id = stable_id("ship", order_id)
    db.update_order(
        order_id,
        status="preparing_shipment",
        workflow_status="packing",
        shipment_id=shipment_id,
    )
    db.append_event(
        order_id,
        "shipment_prepared",
        "Prepared a premium packing manifest.",
        {"shipment_id": shipment_id, "delivery_speed": order["delivery_speed"]},
    )
    return {"shipment_id": shipment_id}


@activity.defn
async def send_concierge_notification(order_id: str) -> dict[str, object]:
    order = db.get_order(order_id)
    if order is None:
        raise RuntimeError(f"missing order {order_id}")

    await asyncio.sleep(0.15)
    notification_id = f"msg-{uuid4().hex[:12]}"
    db.update_order(
        order_id,
        status="complete",
        workflow_status="completed",
        notification_id=notification_id,
    )
    db.append_event(
        order_id,
        "order_complete",
        "Sent the final concierge confirmation.",
        {"notification_id": notification_id},
    )
    logger.info("order completed", extra={"order_id": order_id, "notification_id": notification_id})
    return {"notification_id": notification_id}

