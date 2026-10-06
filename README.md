# Aster Studio

A premium Temporal-native commerce demo with a polished frontend, a containerized backend, and a Postgres database.

The point of the project is not just to look good. It is to feel like a high-end product and to structure the moving parts in a way Temporal can actually own:

- the website handles the customer experience
- the backend creates orders and starts workflows
- the database stores the source of truth
- the worker performs the business actions
- Temporal keeps the state durable and retryable

## What is included

- A luxury-style landing page for a fictional premium product
- A FastAPI backend with order creation and order status APIs
- A Temporal workflow that reserves inventory, captures payment, prepares shipment, and sends a concierge notification
- A Postgres database for orders and events
- Docker Compose for the whole local stack
- ECS deployment notes for AWS
- A production platform baseline for the AWS rollout

## Run locally

```bash
cp .env.example .env
make up
make hero
```

Then open:

- Website: `http://localhost:8000`
- Temporal UI: `http://localhost:8080`

## Demo flow

1. Start the stack with `make up`
2. Open the site and place an order
3. Watch Temporal retry the payment step if the first attempt fails
4. Open Temporal UI and inspect the workflow history

## Project shape

```text
app/            FastAPI backend, Temporal activities and workflows
app/static/     Premium frontend CSS, JS, and hero image
app/templates/  Main landing page template
db/             Postgres init scripts
dynamicconfig/  Temporal local config
ecs/            AWS ECS deployment notes
docs/           AWS access and production-platform decisions
scripts/        Small helper scripts
```

## Production direction

The approved target is documented in [the production platform baseline](docs/platform-baseline.md).
It separates the app and worker on ECS Fargate, uses RDS for application data,
and uses Temporal Cloud outside local development.

For the Terraform-driven staging rollout, see [the staging deployment guide](docs/staging-deployment.md).
