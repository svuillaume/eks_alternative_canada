# Find existing VPC
data "aws_vpc" "sam_vpc" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

# Find public subnet
data "aws_subnet" "sam_vpc_public" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnet_name]
  }
  vpc_id = data.aws_vpc.sam_vpc.id
}

# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for bastion host
resource "aws_security_group" "bastion_sg" {
  name_prefix = "bastion-host-"
  vpc_id      = data.aws_vpc.sam_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-host-sg"
  }
}

# Bastion EC2 instance
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu_22_04.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnet.sam_vpc_public.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  key_name                   = var.key_name

  tags = {
    Name = "bastion-host"
  }
}

# Outputs
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP of the bastion host"
  value       = aws_instance.bastion.private_ip
}

output "ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "ssh -i ${var.ssh_key_path} ubuntu@${aws_instance.bastion.public_ip}"
}

