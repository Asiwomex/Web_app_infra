variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alert_emails" {
  description = "List of email addresses to subscribe to the alerts SNS topic"
  type        = list(string)
  default     = []
}

variable "rds_primary_id" {
  description = "RDS primary DB instance identifier"
  type        = string
}

variable "rds_replica_id" {
  description = "RDS read replica instance identifier"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (the part after loadbalancer/) — used for CloudWatch dimensions"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix"
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
