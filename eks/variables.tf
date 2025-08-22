variable "region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"  # or remove default if you want to pass explicitly
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "node_groups" {
  description = "EKS managed node groups"
  type        = map(any)
}

