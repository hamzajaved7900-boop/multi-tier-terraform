variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "db_password" {
  description = "RDS root password"
  type        = string
  sensitive   = true
  default     = "AdminPass123Secure!"
}