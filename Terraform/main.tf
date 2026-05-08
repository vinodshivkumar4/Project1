provider "aws" {
  region = var.region
}

# 1. Dynamic AMI Data Source
# This automatically finds the correct ID for your region (Mumbai, Virginia, etc.)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS Account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 2. Generate SSH Key Pair
resource "tls_private_key" "node_app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.node_app_key.public_key_openssh
}

# 3. Security Group
resource "aws_security_group" "node_app_sg" {
  name        = "nodejs-app-sg"
  description = "Allow SSH and Node.js App Traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. EC2 Instance
resource "aws_instance" "node_app_server" {
  # Updated to use the data source instead of a hardcoded ID
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.node_app_sg.id]

  # Links to your install_docker.sh script
  user_data = file("${path.module}/install_docker.sh")

  tags = {
    Name        = "nodejs-devops-server"
    Application = "NodeJS-App"
    ManagedBy   = "Terraform"
  }
}