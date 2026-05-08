provider "aws" {
  region = var.region
}

# 1. Generate SSH Key Pair
resource "tls_private_key" "node_app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.node_app_key.public_key_openssh
}

# 2. Security Group
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

# 3. EC2 Instance
resource "aws_instance" "node_app_server" {
  ami                    = "ami-03f487875bd4384ee" # Update this based on your region
  instance_type          = var.instance_type
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.node_app_sg.id]

  # Links to the script in your 'Terraform' folder from the image
  user_data = file("${path.module}/install_docker.sh")

  tags = {
    Name = "nodejs-devops-server"
  }
}