from __future__ import annotations

from contextlib import contextmanager
from typing import Iterator

from psycopg.rows import dict_row
from psycopg.types.json import Jsonb
from psycopg_pool import ConnectionPool

from app.config import settings

_pool: ConnectionPool | None = None


SCHEMA_SQL = """
CREATE TABLE IF NOT EXISTS orders (
    id TEXT PRIMARY KEY,
    workflow_id TEXT NOT NULL,
    customer_name TEXT NOT NULL,
    email TEXT NOT NULL,
    finish TEXT NOT NULL,
    memory TEXT NOT NULL,
    engraving TEXT,
    delivery_speed TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    total_cents INTEGER NOT NULL,
    status TEXT NOT NULL,
    workflow_status TEXT NOT NULL DEFAULT 'created',
    reservation_id TEXT,
    receipt_id TEXT,
    shipment_id TEXT,
    notification_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS order_events (
    id BIGSERIAL PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    step TEXT NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_events_order_id_created_at ON order_events(order_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
"""


def pool() -> ConnectionPool:
    global _pool
    if _pool is None:
        _pool = ConnectionPool(settings.database_url, kwargs={"row_factory": dict_row})
    return _pool


def init_db() -> None:
    with pool().connection() as conn:
        with conn.cursor() as cursor:
            cursor.execute(SCHEMA_SQL)
        conn.commit()


@contextmanager
def cursor() -> Iterator:
    with pool().connection() as conn:
        with conn.cursor() as cur:
            yield conn, cur
        conn.commit()
def create_order(order: dict[str, object], workflow_id: str, quote: dict[str, object]) -> dict[str, object]:
    order_id = order["order_id"]
    with cursor() as (conn, cur):
        cur.execute(
            """
            INSERT INTO orders (
                id, workflow_id, customer_name, email, finish, memory,
                engraving, delivery_speed, quantity, total_cents, status, workflow_status
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                order_id,
                workflow_id,
                order["customer_name"],
                order["email"],
                order["finish"],
                order["memory"],
                order["engraving"],
                order["delivery_speed"],
                order["quantity"],
                quote["total_cents"],
                "queued",
                "created",
            ),
        )
    return get_order(order_id) or {}


def get_order(order_id: str) -> dict[str, object] | None:
    with pool().connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT * FROM orders WHERE id = %s", (order_id,))
            row = cur.fetchone()
    return dict(row) if row else None


def list_recent_orders(limit: int) -> list[dict[str, object]]:
    with pool().connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, customer_name, finish, memory, delivery_speed, quantity,
                       total_cents, status, workflow_status, created_at
                FROM orders
                ORDER BY created_at DESC
                LIMIT %s
                """,
                (limit,),
            )
            rows = cur.fetchall()
    return [dict(row) for row in rows]


def list_events(order_id: str) -> list[dict[str, object]]:
    with pool().connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT step, message, metadata, created_at
                FROM order_events
                WHERE order_id = %s
                ORDER BY created_at ASC, id ASC
                """,
                (order_id,),
            )
            rows = cur.fetchall()
    return [dict(row) for row in rows]


def append_event(order_id: str, step: str, message: str, metadata: dict[str, object] | None = None) -> None:
    with cursor() as (_, cur):
        cur.execute(
            """
            INSERT INTO order_events (order_id, step, message, metadata)
            VALUES (%s, %s, %s, %s)
            """,
            (order_id, step, message, Jsonb(metadata or {})),
        )


def update_order(order_id: str, *, status: str, workflow_status: str, **fields: object) -> None:
    assignments = ["status = %s", "workflow_status = %s", "updated_at = NOW()"]
    values: list[object] = [status, workflow_status]
    for key, value in fields.items():
        assignments.append(f"{key} = %s")
        values.append(value)
    values.append(order_id)
    with cursor() as (_, cur):
        cur.execute(f"UPDATE orders SET {', '.join(assignments)} WHERE id = %s", tuple(values))
