from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class CatalogOption:
    id: str
    label: str
    subtitle: str
    price_cents: int


PRODUCT = {
    "name": "Aster Studio",
    "tagline": "A premium order experience orchestrated by Temporal.",
    "hero": "Crafted to feel calm, fast, and deeply intentional.",
    "summary": "A luxury storefront and operations engine for custom studio hardware.",
    "base_price_cents": 249000,
}

FINISHES = [
    CatalogOption("graphite", "Graphite", "Quiet, architectural, and understated.", 0),
    CatalogOption("silver", "Silver", "Bright, classic, and precise.", 12000),
    CatalogOption("midnight", "Midnight", "Deep, modern, and dramatic.", 18000),
]

MEMORY = [
    CatalogOption("16gb", "16 GB", "For focused everyday creative work.", 0),
    CatalogOption("32gb", "32 GB", "For heavier design and development.", 30000),
    CatalogOption("64gb", "64 GB", "For the most demanding studio builds.", 78000),
]

DELIVERY = [
    CatalogOption("standard", "Standard", "Delivers in 7 to 9 days.", 0),
    CatalogOption("priority", "Priority", "Moves to the front of the queue.", 12000),
    CatalogOption("concierge", "Concierge", "White-glove delivery and setup.", 28000),
]

HIGHLIGHTS = [
    "One clean system for a premium customer journey.",
    "Temporal handles retries, recovery, and order orchestration.",
    "Postgres stores the source of truth for orders and events.",
    "Ready to map cleanly to ECS, RDS, ALB, and Secrets Manager.",
]

STATS = [
    {"label": "Fulfillment latency", "value": "< 90s", "detail": "for demo workflows"},
    {"label": "Workflow state", "value": "durable", "detail": "stored by Temporal"},
    {"label": "Runtime shape", "value": "containers", "detail": "web, worker, db, temporal"},
]


def option_payload(options: list[CatalogOption]) -> list[dict[str, object]]:
    return [
        {
            "id": option.id,
            "label": option.label,
            "subtitle": option.subtitle,
            "price_cents": option.price_cents,
        }
        for option in options
    ]


def payload() -> dict[str, object]:
    return {
        "product": PRODUCT,
        "finishes": option_payload(FINISHES),
        "memory": option_payload(MEMORY),
        "delivery": option_payload(DELIVERY),
        "highlights": HIGHLIGHTS,
        "stats": STATS,
    }


def quote(order: dict[str, object]) -> dict[str, object]:
    finish = next(option for option in FINISHES if option.id == order["finish"])
    memory = next(option for option in MEMORY if option.id == order["memory"])
    delivery = next(option for option in DELIVERY if option.id == order["delivery_speed"])

    subtotal = PRODUCT["base_price_cents"] + finish.price_cents + memory.price_cents
    total = subtotal + delivery.price_cents * int(order["quantity"])

    return {
        "base_price_cents": PRODUCT["base_price_cents"],
        "finish_price_cents": finish.price_cents,
        "memory_price_cents": memory.price_cents,
        "delivery_price_cents": delivery.price_cents,
        "subtotal_cents": subtotal,
        "total_cents": total,
        "currency": "USD",
    }

