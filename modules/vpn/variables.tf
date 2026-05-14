variable "project_name" {
  description = "Project identifier used to prefix all resource names"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID where the VPN instance is placed"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the VPN instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the OpenVPN server"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for emergency SSH break-glass access"
  type        = string
}

variable "vpn_client_cidr" {
  description = "CIDR block assigned to connected VPN clients"
  type        = string
  default     = "172.27.232.0/24"
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
