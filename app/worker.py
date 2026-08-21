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
    await worker.run()


if __name__ == "__main__":
    asyncio.run(main())

