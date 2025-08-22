# Find existing VPC by tag name
data "aws_vpc" "sam_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Find private subnet by tag name
data "aws_subnet" "sam_vpc_private" {
  filter {
    name   = "tag:Name"
    values = [var.private_subnet_name]
  }
  vpc_id = data.aws_vpc.sam_vpc.id
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

# Security group for SSH and MongoDB access
resource "aws_security_group" "mongodb_sg" {
  name_prefix = "mongodb-instance-"
  vpc_id      = data.aws_vpc.sam_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.sam_vpc.cidr_block]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.sam_vpc.cidr_block]
  }

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

# EC2 instance for MongoDB
resource "aws_instance" "mongodb_instance" {
  ami                    = data.aws_ami.ubuntu_20_04.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.sam_vpc_private.id
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 100
    encrypted   = true
    tags = {
      Name = "mongodb-instance-root-volume"
    }
  }

  user_data = file("${path.module}/mongodb.tpl")

  tags = {
    Name        = "mongodb-instance"
    Environment = "demo"
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

