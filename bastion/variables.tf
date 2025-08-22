variable "vpc_name" {
  description = "Name of the VPC to find"
  type        = string
}

variable "public_subnet_name" {
  description = "Name of the public subnet"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for bastion host"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to the SSH private key file"
  type        = string
}

