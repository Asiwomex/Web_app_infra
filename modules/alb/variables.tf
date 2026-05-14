variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  description = "At least two public subnet IDs across different AZs"
  type        = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "domain_name" {
  description = "FQDN for the ALB (e.g. dev.theboateng.me)"
  type        = string
}

variable "route53_zone_id" {
  type = string
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (must have ELB write policy)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
