variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "platform_subnet_ids" {
  type = list(string)
}

variable "database_subnet_ids" {
  type = list(string)
}

variable "application_subnet_ids" {
  type = list(string)
}
