variable "project" {
  default = "cdr"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "az" {
  default = "us-east-1a"
}

variable "admin_ip" {
  description = "Your home public IP in CIDR form, e.g. 1.2.3.4/32"
  type        = string
}

variable "instance_type" {
  default = "t3.micro"
}

variable "alert_email" {
  description = "Where response alerts are sent"
  type        = string
}

variable "enable_ssm_endpoints" {
  description = "Interface endpoints for Session Manager in the private subnet (~$0.72/day)"
  type        = bool
  default     = true
}
