# ECS Learning Project

This project builds a small but realistic AWS ECS/Fargate service:

* A VPC with public and private subnets across two Availability Zones
* An Internet Gateway, NAT Gateway, route tables, and subnet associations
* An internet-facing Application Load Balancer
* An ECS cluster and Fargate service running `nginx`
* CloudWatch logs and CPU-based service autoscaling

The first tangible outcome is a public ALB DNS name that serves the container after `terraform apply`.

## Project layout

```text
.
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars.example
└── modules
    ├── alb
    ├── ecs
    └── vpc
```

## Try it

Copy the example variables if you want to customize values:

```sh
cp terraform.tfvars.example terraform.tfvars
```

Then run:

```sh
terraform init
terraform plan
terraform apply
```

When the apply finishes, Terraform prints `alb_dns_name`. Open that URL to see the running container.

## CI and AWS access

This repo includes a GitHub Actions workflow at `.github/workflows/terraform-ci.yml`.

The CI runs:

* `terraform fmt -check -recursive`
* `terraform init -backend=false`
* `terraform validate -no-color`
* `terraform plan` when an AWS role is configured

The best way to connect GitHub Actions to AWS is OpenID Connect (OIDC), not long-lived access keys.

Create an IAM role in AWS that trusts GitHub's OIDC provider and allows only this repository/branch to assume it. See `docs/github-oidc-aws.md` for a concrete trust-policy example. Then add these repository variables in GitHub:

* `AWS_ROLE_TO_ASSUME`: the IAM role ARN, for example `arn:aws:iam::123456789012:role/github-actions-terraform-ecs`
* `AWS_REGION`: the AWS region, for example `us-east-1`

Avoid storing `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in GitHub secrets for Terraform CI. Use access keys only as a temporary local fallback, rotate them quickly, and keep permissions narrow.

## Clean up

This stack creates billable AWS resources, including a NAT Gateway and Fargate tasks. Destroy it when you are done learning:

```sh
terraform destroy
```
