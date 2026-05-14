variable "project_name" {
  description = "Project identifier used to prefix all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where subnets are created; used to derive AZ suffixes"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_az1_cidr" {
  description = "CIDR for the public subnet in AZ1 (hosts ALB, NAT GW)"
  type        = string
}

variable "public_subnet_az2_cidr" {
  description = "CIDR for the public subnet in AZ2 (hosts ALB)"
  type        = string
}

variable "private_subnet_az1_cidr" {
  description = "CIDR for the private subnet in AZ1 (hosts app servers, RDS primary)"
  type        = string
}

variable "private_subnet_az2_cidr" {
  description = "CIDR for the private subnet in AZ2 (hosts app servers, RDS replica)"
  type        = string
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway in AZ1 only. Set false in prod to get a per-AZ NAT GW so an AZ1 failure does not cut off AZ2 outbound traffic."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
