variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "vpc_name" {
  description = "Name tag of the existing VPC"
  type        = string
  default     = "sam-vpc"
}

variable "private_subnet_name" {
  description = "Name tag of the private subnet"
  type        = string
  default     = "sam-vpc-private-ca-central-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "samv-ssh"
}

