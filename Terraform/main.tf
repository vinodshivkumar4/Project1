data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 1. REMOVED: aws_key_pair.generated_key block
# 2. REMOVED: tls_private_key.node_app_key block

resource "aws_security_group" "node_app_sg" {
  name        = "nodejs-app-sg"
  description = "Allow SSH and App Port"

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

resource "aws_instance" "node_app_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  
  # 3. UPDATED: Using your existing AWS Key Pair name
  key_name               = "Jenkins_007" 
  
  vpc_security_group_ids = [aws_security_group.node_app_sg.id]
  user_data              = file("${path.module}/install_docker.sh")

  tags = {
    Name = "nodejs-devops-server"
  }
}