# Production Platform Baseline

This document defines the target operating model for Aster Studio. It is an
architecture decision record for the move from the local Compose demo to AWS;
it does not create or modify cloud resources.

## Decisions

| Area | Decision |
| --- | --- |
| AWS region | `us-east-1` for the initial deployment. |
| Environments | Separate `dev`, `staging`, and `prod` environments, each with isolated state, networking, data, and secrets. |
| Compute | AWS ECS on Fargate, with independent `app` and `worker` services. |
| Workflow platform | Temporal Cloud in each non-local environment; local Docker Temporal remains for development only. |
| Application database | Amazon RDS for PostgreSQL, private and encrypted. |
| Container registry | Amazon ECR; deployments use immutable image digests. |
| Public entry point | Internet-facing Application Load Balancer terminating TLS, routing only to the `app` service. |
| Secrets | AWS Secrets Manager, injected into ECS tasks at runtime. |
| IaC state | Remote Terraform state with locking and encryption. |

## Environment model

`dev` is an integration environment that may be changed frequently. `staging`
is production-like and receives the release candidate. `prod` is customer
facing and changes only through the protected deployment workflow.

| Control | Dev | Staging | Production |
| --- | --- | --- | --- |
| AWS account | Isolated account or equivalent strict boundary | Isolated account | Isolated account |
| Terraform state | Dedicated backend key | Dedicated backend key | Dedicated backend key |
| Deploy trigger | Merge to development branch | Promotion from main | Approved promotion from staging |
| Data | Disposable, synthetic | Synthetic, refreshable | Customer data only |
| Destructive changes | Allowed with review | Reviewed | Approved change with backup/rollback plan |

Use separate AWS accounts where the organization can support them. If the
initial rollout must share an account, use separate VPCs, KMS keys, IAM roles,
Terraform state keys, and resource naming per environment; do not share RDS
instances or secrets.

## Service boundaries

```text
Internet
  |
  v
ALB (HTTPS :443)
  |
  v
app ECS service (private subnets, :8000) ----> RDS PostgreSQL (private)
  |
  +------------------------------------------> Temporal Cloud

worker ECS service (private subnets, no inbound listener)
  |-------------------------------> RDS PostgreSQL (private)
  +-------------------------------> Temporal Cloud
```

- `app` serves the web UI and HTTP API, starts workflows, and reads order state.
- `worker` polls Temporal and executes activities. It receives no ALB target,
  no public IP, and no inbound security-group rule.
- RDS accepts connections only from the `app` and `worker` task security group.
- Temporal Cloud credentials and endpoint are accessible only to the two task
  roles through Secrets Manager.

## Availability and recovery expectations

Initial targets, to be validated after staging load tests:

| Service | Availability target | Recovery expectation |
| --- | --- | --- |
| Customer API | 99.9% monthly | Roll back a bad release within 15 minutes. |
| Order workflow execution | 99.9% monthly acceptance | Durable Temporal retries; alert if a workflow remains open beyond 15 minutes. |
| Order database | RDS Multi-AZ in production | Automated backups with point-in-time recovery; restore exercise every quarter. |

The API must expose separate liveness and readiness checks. Readiness includes
database connectivity and Temporal connectivity. An unhealthy task must be
removed from the ALB, while a worker that cannot poll Temporal must fail its
ECS health check and be restarted.

## Security baseline

- TLS is mandatory at the ALB; redirect HTTP to HTTPS.
- ECS tasks run in private subnets with no public IPs.
- Use task roles with least privilege; task execution roles only pull images,
  write logs, and retrieve the explicitly required secrets.
- Store no credentials in Git, Terraform defaults, container images, or ECS
  environment-variable definitions.
- Encrypt RDS storage, backups, Terraform state, ECR, and CloudWatch Logs with
  managed KMS keys appropriate to each environment.
- Require GitHub Actions OIDC roles, protected branches, and production
  deployment approval.

## Explicit non-goals

- Self-hosting Temporal on ECS or RDS outside local development.
- Public access to workers, PostgreSQL, or Temporal administrative endpoints.
- Deploying the current generic Nginx Terraform service as Aster Studio.

## Exit criteria for this stage

- The team approves the decisions in this document or records substitutions.
- AWS account IDs, DNS ownership, Temporal Cloud namespace details, and
  Terraform remote-state location are available for the staging build.
- The next implementation stage can replace the generic ECS module with the
  `app` and `worker` services specified above.
