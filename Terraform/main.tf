resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.node_app_key.public_key_openssh
}

resource "tls_private_key" "node_app_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

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
    from_port   = 3000 # Your Node.js App Port
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

resource "aws_instance" "node_app_server" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.node_app_sg.id]

  # Production Best Practice: Using a dedicated shell script for user_data
  user_data = file("${path.module}/scripts/install_docker.sh")

  tags = {
    Name        = "nodejs-devops-server"
    Application = "NodeJS-App"
    ManagedBy   = "Terraform"
  }
}