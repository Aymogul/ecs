variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "us-east-1"
}

variable "env" {
  type        = string
  description = "Environment name used in resource names."
  default     = "dev"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets."
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the public and private subnets."
  default     = ["us-east-1a", "us-east-1b"]
}

variable "listener_port" {
  type        = number
  description = "Public ALB listener port."
  default     = 80
}

variable "container_port" {
  type        = number
  description = "Container port exposed through the ALB."
  default     = 80
}

variable "image" {
  type        = string
  description = "Container image for the ECS service."
  default     = "nginx:latest"
}

variable "cpu" {
  type        = number
  description = "Fargate task CPU units."
  default     = 256
}

variable "memory" {
  type        = number
  description = "Fargate task memory in MiB."
  default     = 512
}

variable "desired_count" {
  type        = number
  description = "Number of ECS tasks to run."
  default     = 2
}

variable "log_retention" {
  type        = number
  description = "CloudWatch log retention in days."
  default     = 7
}

variable "min_capacity" {
  type        = number
  description = "Minimum task count for autoscaling."
  default     = 2
}

variable "max_capacity" {
  type        = number
  description = "Maximum task count for autoscaling."
  default     = 4
}
