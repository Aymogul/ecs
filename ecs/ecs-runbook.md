# ECS Deployment Notes

This app is designed to move cleanly into AWS without rewriting the shape.

## Suggested AWS resources

- `app` container on ECS Fargate behind an ALB
- `worker` container on ECS Fargate without public ingress
- `postgres` mapped to Amazon RDS PostgreSQL or Aurora PostgreSQL
- `temporal` mapped to Temporal Cloud or a private ECS service with managed persistence
- Secrets in AWS Secrets Manager or SSM Parameter Store
- Logs in CloudWatch

## Why this structure works

- The website stays fast and simple.
- The backend owns order creation and reads from the database.
- Temporal handles retries, activity state, and workflow history.
- The worker is stateless and can be replaced at any time.

## ECS service split

- `app` service: public, behind ALB, serves the premium website and API
- `worker` service: private, polls the task queue and performs activities
- `temporal` service: private, reachable only by the app and worker

## Production notes

- Keep Temporal private or use Temporal Cloud.
- Use separate credentials for the app database and Temporal persistence.
- Make order creation idempotent so retries do not duplicate rows.
- Treat fulfillment activities as retriable operations with stable identifiers.

