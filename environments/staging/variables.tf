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

variable "vpc_cidr" {
  type    = string
  default = "10.0.4.0/22"
}

variable "public_subnet_az1_cidr" {
  type    = string
  default = "10.0.4.0/25"
}

variable "public_subnet_az2_cidr" {
  type    = string
  default = "10.0.4.128/25"
}

variable "private_subnet_az1_cidr" {
  type    = string
  default = "10.0.5.0/24"
}

variable "private_subnet_az2_cidr" {
  type    = string
  default = "10.0.6.0/24"
}

variable "key_pair_name" {
  type = string
}

variable "app_instance_type" {
  type    = string
  default = "t3.medium"
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

variable "create_replica" {
  description = "Whether to create an RDS read replica"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Whether to deploy WAF in front of the ALB"
  type        = bool
  default     = false
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 100
}

variable "alb_domain_name" {
  type    = string
  default = "stage.insight-edgecs.com"
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "waf_rate_limit" {
  type    = number
  default = 2000
}

variable "cognito_callback_urls" {
  type    = list(string)
  default = ["https://stage.insight-edgecs.com/callback"]
}

variable "cognito_logout_urls" {
  type    = list(string)
  default = ["https://stage.insight-edgecs.com/logout"]
}
