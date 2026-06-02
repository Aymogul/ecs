# VPC Module

This module creates a VPC with public and private subnets, as well as an Internet Gateway and a NAT Gateway.

## Inputs

* `region`: The AWS region where the VPC will be created.
* `env`: The environment name (e.g. "dev", "prod").
* `vpc_cidr`: The CIDR block for the VPC.
* `public_subnets`: A list of public subnet CIDRs.
* `private_subnets`: A list of private subnet CIDRs.
* `availability_zones`: A list of availability zones.

## Outputs

* `vpc_id`: The ID of the VPC.
* `public_subnet_ids`: A list of public subnet IDs.
* `private_subnet_ids`: A list of private subnet IDs.
* `nat_gateway_id`: The ID of the NAT Gateway.
