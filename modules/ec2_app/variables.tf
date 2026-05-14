variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnet IDs across AZs — ASG distributes instances across these"
  type        = list(string)
}

variable "security_group_id" {
  type = string
}

variable "target_group_arn" {
  description = "ALB target group ARN — ASG registers instances with this target group"
  type        = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for emergency break-glass SSH access (optional)"
  type        = string
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances the ASG can scale to"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances at steady state"
  type        = number
  default     = 2
}

variable "tags" {
  type    = map(string)
  default = {}
}
