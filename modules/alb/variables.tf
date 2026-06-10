variable "region" {
  type        = string
  description = "AWS region used by the root provider."
}

variable "env" {
  type        = string
  description = "Environment name used for resource names and tags."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the ALB and target group are created."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for the internet-facing ALB."
}

variable "listener_port" {
  type        = number
  description = "ALB listener port."
  default     = 80
}

variable "target_port" {
  type        = number
  description = "Port the target group forwards to."
  default     = 80
}

variable "health_check_path" {
  type        = string
  description = "HTTP path used by the target group health check."
  default     = "/"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to reach the ALB listener."
  default     = ["0.0.0.0/0"]
}
