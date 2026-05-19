variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group (needs 2+ AZs)"
  type        = list(string)
}

variable "security_group_id" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "instance_class" {
  description = "RDS instance class for the primary"
  type        = string
  default     = "db.t3.micro"
}

variable "replica_instance_class" {
  description = "RDS instance class for the read replica"
  type        = string
  default     = "db.t3.micro"
}

variable "create_replica" {
  description = "Whether to create a read replica. Set false for non-prod to save cost."
  type        = bool
  default     = true
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum autoscaling storage in GB"
  type        = number
  default     = 100
}

variable "primary_az" {
  description = "AZ for the primary DB (e.g. us-east-1a)"
  type        = string
}

variable "replica_az" {
  description = "AZ for the read replica (e.g. us-east-1b)"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
