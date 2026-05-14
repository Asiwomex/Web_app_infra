variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alb_arn" {
  type = string
}

variable "rate_limit" {
  description = "Max requests per 5-minute window per IP before blocking"
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
