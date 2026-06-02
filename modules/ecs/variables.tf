variable "region" {
  type        = string
}

variable "env" {
  type        = string
}

variable "cpu" {
  type        = number
}

variable "memory" {
  type        = number
}

variable "image" {
  type        = string
}

variable "container_port" {
  type        = number
}

variable "desired_count" {
  type        = number
}

variable "log_retention" {
  type        = number
}

variable "max_capacity" {
  type        = number
}

variable "min_capacity" {
  type        = number
}

variable "scaling_adjustment" {
  type        = number
}
