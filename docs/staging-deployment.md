# Staging deployment

This configuration deploys the Aster Studio application and Temporal worker to
ECS Fargate. Temporal itself remains managed by Temporal Cloud.

## What Terraform creates

- VPC, public/private subnets, NAT gateway, and an internet-facing ALB
- Private RDS PostgreSQL for application orders
- ECR repository with immutable tags and scan-on-push
- ECS cluster, public `app` service, and private `worker` service
- CloudWatch log group, task execution role, security groups, and runtime
  secrets in AWS Secrets Manager

It does not create an AWS account, a Temporal Cloud tenant, or a DNS domain.

## Required inputs

1. Create a Temporal Cloud staging namespace and API key.
2. Build and push the application image to the ECR repository output by an
   initial bootstrap apply, or create the ECR repository separately first.
3. Copy `terraform.tfvars.example` to a private `staging.tfvars` file and set:
   - `app_image` to an immutable ECR image digest
   - `temporal_cloud_address`
   - `temporal_cloud_namespace`
4. Supply `temporal_cloud_api_key` through the CI environment as
   `TF_VAR_temporal_cloud_api_key`; do not commit it.

Because the runtime API key is written to Secrets Manager by Terraform, the
Terraform backend must be encrypted and access must be restricted. Production
should instead use a CI-controlled secret-injection pattern or a separately
managed secret value.

## Commands

```bash
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars
```

After apply, open the `alb_dns_name` output, place an order, and confirm the
workflow is visible in the Temporal Cloud namespace. Use a production tfvars
file that enables RDS Multi-AZ, deletion protection, and final snapshots.
