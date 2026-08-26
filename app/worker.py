from __future__ import annotations

import asyncio
import logging

from temporalio.client import Client
from temporalio.worker import Worker

from app.activities import capture_payment, prepare_shipment, reserve_inventory, send_concierge_notification
from app.config import settings
from app.workflows import AsterOrderWorkflow


async def main() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    while True:
        client = await Client.connect(
            settings.temporal_address,
            namespace=settings.temporal_namespace,
        )
        worker = Worker(
            client,
            task_queue=settings.task_queue,
            workflows=[AsterOrderWorkflow],
            activities=[
                reserve_inventory,
                capture_payment,
                prepare_shipment,
                send_concierge_notification,
            ],
        )
        logging.info("worker listening on task queue %s", settings.task_queue)
        try:
            await worker.run()
        except RuntimeError as exc:
            if "Namespace" not in str(exc) or "not found" not in str(exc):
                raise
            logging.warning("Temporal namespace is not ready; retrying in two seconds")
            await asyncio.sleep(2)


if __name__ == "__main__":
    asyncio.run(main())
