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
  default = "insight-edgecs.com"
}

# ─── VPC ──────────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  type    = string
  default = "10.0.12.0/22"
}

variable "public_subnet_az1_cidr" {
  type    = string
  default = "10.0.12.0/25"
}

variable "public_subnet_az2_cidr" {
  type    = string
  default = "10.0.12.128/25"
}

variable "private_subnet_az1_cidr" {
  type    = string
  default = "10.0.13.0/24"
}

variable "private_subnet_az2_cidr" {
  type    = string
  default = "10.0.14.0/24"
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
  default = 20
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

# ─── RDS (shared between dev and staging sub-environments) ────────────────────

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

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 50
}

# ─── ALB ──────────────────────────────────────────────────────────────────────

variable "health_check_path" {
  type    = string
  default = "/health"
}

# ─── Alerting ─────────────────────────────────────────────────────────────────

variable "alert_emails" {
  description = "Email addresses for CloudWatch alarm notifications"
  type        = list(string)
  default     = []
}
