variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test or prod."
  }
}

variable "vpc_cidr" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
  ephemeral = true
}