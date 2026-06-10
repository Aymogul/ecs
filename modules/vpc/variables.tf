variable "region" {
  type        = string
  description = "AWS region used by the root provider."
}

variable "env" {
  type        = string
  description = "Environment name used for resource names and tags."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDR blocks for public subnets."
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDR blocks for private subnets."
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones matching the subnet lists."
}
