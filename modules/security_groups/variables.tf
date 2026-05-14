variable "project_name" {
  description = "Project identifier used to prefix all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID in which to create the security groups"
  type        = string
}

variable "app_port" {
  description = "Port the application listens on — ALB forwards to this port and the app SG allows it"
  type        = number
  default     = 8080
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
