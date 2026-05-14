variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "callback_urls" {
  description = "List of allowed OAuth callback URLs"
  type        = list(string)
}

variable "logout_urls" {
  description = "List of allowed logout URLs"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
