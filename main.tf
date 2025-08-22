provider "aws" {
  region = var.region
}

module "eks" {
  source          = "./eks"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  cluster_version = var.cluster_version
  node_groups     = var.node_groups
}

module "bastion" {
  source          = "./bastion"
  vpc_name        = var.vpc_name
  public_subnet_name = var.public_subnet_name
  instance_type   = var.bastion_instance_type
  key_name       = var.key_name
  ssh_key_path   = var.ssh_key_path
}

module "mongodb" {
  source = "./mongodb"

  vpc_name             = var.mongodb_vpc_name
  private_subnet_name  = var.mongodb_private_subnet_name
  instance_type        = var.mongodb_instance_type
  key_name             = var.mongodb_key_name
}

resource "aws_iam_policy" "pass_role_policy" {
  name        = "AllowPassRoleForEksAddons"
  description = "Allow iam:PassRole for EKS addon roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "iam:PassRole"
      Resource = "arn:aws:iam::244822573207:role/*`"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_pass_role_policy" {
  role       = "terraform-role"
  policy_arn = aws_iam_policy.pass_role_policy.arn
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "bastion_public_ip" {
  value = module.bastion.bastion_public_ip
}

output "mongodb_instance_id" {
  description = "ID of the MongoDB EC2 instance"
  value       = module.mongodb.instance_id
}

output "mongodb_instance_private_ip" {
  description = "Private IP of the MongoDB EC2 instance"
  value       = module.mongodb.instance_private_ip
}

output "mongodb_connection_string" {
  description = "MongoDB connection string for internal use"
  value       = module.mongodb.mongodb_connection_string
}

