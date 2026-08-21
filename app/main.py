from __future__ import annotations

import logging
from uuid import uuid4

from fastapi.encoders import jsonable_encoder
from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from temporalio.client import Client

from app import catalog, db
from app.config import settings
from app.schemas import OrderCreate
from app.workflows import AsterOrderWorkflow

logger = logging.getLogger(__name__)
templates = Jinja2Templates(directory="app/templates")

app = FastAPI(title=settings.app_name, version="1.0.0")
app.mount("/static", StaticFiles(directory="app/static"), name="static")


@app.on_event("startup")
async def startup() -> None:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    db.init_db()
    try:
        app.state.temporal = await Client.connect(
            settings.temporal_address,
            namespace=settings.temporal_namespace,
        )
        logger.info("connected to temporal at %s", settings.temporal_address)
    except Exception as exc:  # pragma: no cover - startup fallback
        app.state.temporal = None
        logger.warning("temporal unavailable at startup: %s", exc)


@app.on_event("shutdown")
async def shutdown() -> None:
    temporal = getattr(app.state, "temporal", None)
    if temporal is not None:
        await temporal.close()


@app.get("/", response_class=HTMLResponse)
def home(request: Request) -> HTMLResponse:
    recent_orders = db.list_recent_orders(settings.recent_orders_limit)
    initial_state = jsonable_encoder({
        "catalog": catalog.payload(),
        "recent_orders": recent_orders,
    })
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "app_name": settings.app_name,
            "initial_state": initial_state,
        },
    )


@app.get("/api/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "temporal_ready": getattr(app.state, "temporal", None) is not None,
    }


@app.get("/api/catalog")
def get_catalog() -> dict[str, object]:
    return catalog.payload()


@app.get("/api/orders/recent")
def recent_orders() -> dict[str, object]:
    return {"orders": db.list_recent_orders(settings.recent_orders_limit)}


@app.get("/api/orders/{order_id}")
def get_order(order_id: str) -> dict[str, object]:
    order = db.get_order(order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return {"order": order, "events": db.list_events(order_id)}


@app.post("/api/orders")
async def create_order(payload: OrderCreate) -> dict[str, object]:
    temporal = getattr(app.state, "temporal", None)
    if temporal is None:
        raise HTTPException(status_code=503, detail="Temporal is not ready yet")

    order_id = uuid4().hex[:12]
    workflow_id = f"aster-{order_id}"
    quote = catalog.quote(payload.model_dump())
    order_record = db.create_order(
        {
            "order_id": order_id,
            "customer_name": payload.customer_name,
            "email": payload.email,
            "finish": payload.finish,
            "memory": payload.memory,
            "delivery_speed": payload.delivery_speed,
            "engraving": payload.engraving,
            "quantity": payload.quantity,
        },
        workflow_id,
        quote,
    )
    db.append_event(
        order_id,
        "workflow_started",
        "Temporal workflow started for the studio order.",
        {"workflow_id": workflow_id},
    )
    await temporal.start_workflow(
        AsterOrderWorkflow.run,
        order_id,
        id=workflow_id,
        task_queue=settings.task_queue,
    )
    return {
        "order_id": order_id,
        "workflow_id": workflow_id,
        "status": order_record.get("status", "queued"),
        "quote": quote,
    }
