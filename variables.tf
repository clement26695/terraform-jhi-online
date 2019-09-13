variable "dev_ip" {}

variable "database_username" {
  description = "Database Uusername"
  default     = "admin"
}

variable "database_password" {
  description = "Database password"
  default     = "admin"
}

variable "ssh_key_path" {
  description = "Path where a ssh key is stored"
}
