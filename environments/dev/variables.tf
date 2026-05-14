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
  description = "Route 53 zone ID from bootstrap outputs"
  type        = string
}

# ─── VPC ──────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/22"
}

variable "public_subnet_az1_cidr" {
  type    = string
  default = "10.0.0.0/25"
}

variable "public_subnet_az2_cidr" {
  type    = string
  default = "10.0.0.128/25"
}

variable "private_subnet_az1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_az2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

# ─── EC2 ──────────────────────────────────────────────────────────────────────

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair"
  type        = string
}

variable "app_instance_type" {
  type    = string
  default = "t3.small"
}

variable "app_root_volume_size" {
  type    = number
  default = 30
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "asg_min_size" {
  type    = number
  default = 1
}

variable "asg_max_size" {
  type    = number
  default = 2
}

variable "asg_desired_capacity" {
  type    = number
  default = 1
}

variable "alert_emails" {
  description = "Email addresses for CloudWatch alarm notifications"
  type        = list(string)
  default     = []
}

# ─── RDS ──────────────────────────────────────────────────────────────────────

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
  default = "db.t3.micro"
}

variable "db_replica_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 50
}

# ─── ALB ──────────────────────────────────────────────────────────────────────

variable "alb_domain_name" {
  type    = string
  default = "dev.theboateng.me"
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

# ─── WAF ──────────────────────────────────────────────────────────────────────

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

# ─── Cognito ──────────────────────────────────────────────────────────────────

variable "cognito_callback_urls" {
  type    = list(string)
  default = ["https://dev.theboateng.me/callback"]
}

variable "cognito_logout_urls" {
  type    = list(string)
  default = ["https://dev.theboateng.me/logout"]
}
