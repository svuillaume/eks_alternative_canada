variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ca-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "node_groups" {
  description = "Map of node group configurations"
  type        = map(any)
  default     = {}
}

variable "vpc_name" {
  description = "Name tag of existing VPC (for bastion module)"
  type        = string
  default     = "sam-vpc"
}

variable "public_subnet_name" {
  description = "Name tag of public subnet (for bastion module)"
  type        = string
  default     = "sam-vpc-public-ca-central-1a"
}

variable "instance_type" {
  description = "EC2 instance type for bastion"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name for bastion"
  type        = string
  default     = "samv-ssh"
}

variable "ssh_key_path" {
  description = "Path to private SSH key file"
  type        = string
  default     = "~/.ssh/samv-ssh.pem"
}

variable "bastion_instance_type" {
  description = "EC2 instance type for the bastion host"
  type        = string
  default     = "t3.micro" # or whatever you prefer
}

# Variables for MongoDB submodule
variable "mongodb_vpc_name" {
  description = "Name tag of existing VPC for MongoDB instance"
  type        = string
  default     = "sam-vpc"  # or your actual VPC name
}

variable "mongodb_private_subnet_name" {
  description = "Name tag of private subnet for MongoDB instance"
  type        = string
  default     = "sam-vpc-private-ca-central-1a"  # change as needed
}

variable "mongodb_instance_type" {
  description = "EC2 instance type for MongoDB"
  type        = string
  default     = "t3.small"
}

variable "mongodb_key_name" {
  description = "SSH key pair name for MongoDB instance"
  type        = string
  default     = "samv-ssh"
}

