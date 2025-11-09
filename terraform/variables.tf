variable "region" {
  type    = string
  default = "us-east-1"
}

variable "public_key" {
  type      = string
  sensitive = true
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "allow_cidr" {
  description = "CIDR allowed to access services (use your IP/CIDR for security; 0.0.0.0/0 for labs)."
  type        = string
  default     = "0.0.0.0/0"
}
