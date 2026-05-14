variable "domain_name" {
  description = "Root domain name (must match the hosted zone created in bootstrap)"
  type        = string
}

variable "alb_dns_subdomain" {
  description = "Full subdomain for ALB (e.g. dev.theboateng.me)"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name from the aws_lb resource"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB hosted zone ID from the aws_lb resource"
  type        = string
}
