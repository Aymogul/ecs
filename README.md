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

## Clean up

This stack creates billable AWS resources, including a NAT Gateway and Fargate tasks. Destroy it when you are done learning:

```sh
terraform destroy
```
