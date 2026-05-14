variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "insight-edge"
}

variable "domain_name" {
  type    = string
  default = "theboateng.me"
}

variable "route53_zone_id" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.8.0/22"
}

variable "public_subnet_az1_cidr" {
  type    = string
  default = "10.0.8.0/25"
}

variable "public_subnet_az2_cidr" {
  type    = string
  default = "10.0.8.128/25"
}

variable "private_subnet_az1_cidr" {
  type    = string
  default = "10.0.9.0/24"
}

variable "private_subnet_az2_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "key_pair_name" {
  type = string
}

variable "app_instance_type" {
  type    = string
  default = "t3.large"
}

variable "app_root_volume_size" {
  type    = number
  default = 50
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 6
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "alert_emails" {
  description = "Email addresses for CloudWatch alarm notifications — set this in prod"
  type        = list(string)
  default     = []
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_replica_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_allocated_storage" {
  type    = number
  default = 50
}

variable "db_max_allocated_storage" {
  type    = number
  default = 500
}

variable "alb_domain_name" {
  type    = string
  default = "prod.theboateng.me"
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "waf_rate_limit" {
  description = "Max requests per 5 minutes per IP"
  type        = number
  default     = 1000
}

variable "cognito_callback_urls" {
  type    = list(string)
  default = ["https://prod.theboateng.me/callback"]
}

variable "cognito_logout_urls" {
  type    = list(string)
  default = ["https://prod.theboateng.me/logout"]
}
