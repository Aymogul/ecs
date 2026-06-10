variable "region" {
  type        = string
  description = "AWS region used by logs and the root provider."
}

variable "env" {
  type        = string
  description = "Environment name used for resource names and tags."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where ECS task security groups are created."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs where Fargate tasks run."
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group allowed to reach ECS tasks."
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group ARN where the ECS service registers tasks."
}

variable "cpu" {
  type        = number
  description = "Fargate task CPU units."
}

variable "memory" {
  type        = number
  description = "Fargate task memory in MiB."
}

variable "image" {
  type        = string
  description = "Container image to run."
}

variable "container_port" {
  type        = number
  description = "Container port exposed to the ALB."
}

variable "desired_count" {
  type        = number
  description = "Number of tasks to run."
}

variable "log_retention" {
  type        = number
  description = "CloudWatch log retention in days."
}

variable "max_capacity" {
  type        = number
  description = "Maximum ECS service task count for autoscaling."
}

variable "min_capacity" {
  type        = number
  description = "Minimum ECS service task count for autoscaling."
}

variable "assign_public_ip" {
  type        = bool
  description = "Whether Fargate tasks should receive public IPs."
  default     = false
}
