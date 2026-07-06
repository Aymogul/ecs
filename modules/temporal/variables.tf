variable "region" {
  type        = string
  description = "AWS region used by logs."
}

variable "env" {
  type        = string
  description = "Environment name used for resource names and tags."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Temporal resources are created."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the Temporal UI load balancer."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for Temporal tasks and database."
}

variable "allowed_ui_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the Temporal UI."
}

variable "db_username" {
  type        = string
  description = "Temporal PostgreSQL username."
}

variable "db_password" {
  type        = string
  description = "Temporal PostgreSQL password."
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class for Temporal persistence."
}

variable "temporal_image" {
  type        = string
  description = "Temporal server Docker image."
}

variable "temporal_ui_image" {
  type        = string
  description = "Temporal UI Docker image."
}

variable "cpu" {
  type        = number
  description = "Fargate CPU units for the Temporal task."
}

variable "memory" {
  type        = number
  description = "Fargate memory in MiB for the Temporal task."
}

variable "log_retention" {
  type        = number
  description = "CloudWatch log retention in days."
}
