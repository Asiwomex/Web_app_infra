variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier used to prefix all resource names"
  type        = string
  default     = "insight-edge"
}

variable "domain_name" {
  description = "Root domain name for Route 53 hosted zone"
  type        = string
  default     = "theboateng.me"
}

variable "monthly_budget_usd" {
  description = "Account-wide monthly cost ceiling in USD. Triggers email at 80% actual and 100% forecast."
  type        = number
  default     = 1500
}

variable "budget_alert_emails" {
  description = "Email addresses to notify on budget breach. Leave empty to skip the budget."
  type        = list(string)
  default     = []
}
