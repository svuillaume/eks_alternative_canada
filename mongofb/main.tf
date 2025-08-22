terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
       version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
}

# Find existing VPC
data "aws_vpc" "sam-vpc" {
  filter {
    name   = "tag:Name"
    values = ["sam-vpc"]
  }
}

# Find private subnet
data "aws_subnet" "sam-vpc-private-ca-central-1a" {
  filter {
    name   = "tag:Name"
    values = ["sam-vpc-private-ca-central-1a"]
  }
  vpc_id = data.aws_vpc.sam-vpc.id
}

# Get latest Ubuntu 20.04 AMI
data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for SSH and MongoDB
resource "aws_security_group" "mongodb_sg" {
  name_prefix = "mongodb-instance-"
  vpc_id      = data.aws_vpc.sam-vpc.id

  # SSH access - consider restricting to VPC CIDR or bastion host
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.sam-vpc.cidr_block] # More secure than 0.0.0.0/0
  }

  # MongoDB access within VPC
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.sam-vpc.cidr_block]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mongodb-instance-sg"
  }
}

# EC2 instance
resource "aws_instance" "mongodb_instance" {
  ami                    = data.aws_ami.ubuntu_20_04.id
  instance_type          = "t3.small"
  subnet_id              = data.aws_subnet.sam-vpc-private-ca-central-1a.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]

  # Key pair for SSH
  key_name = "samv-ssh"

  # Root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    tags = {
      Name = "mongodb-instance-root-volume"
    }
  }

  # Run your existing template on first boot
  user_data = file("${path.module}/mongodb.tpl")

  tags = {
    Name = "mongodb-instance"
    Environment = "education"
  }
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.mongodb_instance.id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.mongodb_instance.private_ip
}

output "mongodb_connection_string" {
  description = "MongoDB connection string for internal use"
  value       = "mongodb://${aws_instance.mongodb_instance.private_ip}:27017"
}
