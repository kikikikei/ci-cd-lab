
# add near the top
resource "random_id" "suffix" { byte_length = 2 }

resource "aws_key_pair" "lab" {
  key_name   = "ci-cd-lab-key-${random_id.suffix.hex}"
  public_key = var.public_key
}

resource "aws_security_group" "lab_sg" {
  name        = "ci-cd-lab-sg-${random_id.suffix.hex}"
  description = "Allow SSH, HTTP, Prometheus, Grafana"

  ingress { from_port = 22   to_port = 22   protocol = "tcp" cidr_blocks = [var.allow_cidr] }
  ingress { from_port = 80   to_port = 80   protocol = "tcp" cidr_blocks = [var.allow_cidr] }
  ingress { from_port = 9090 to_port = 9090 protocol = "tcp" cidr_blocks = [var.allow_cidr] }
  ingress { from_port = 3000 to_port = 3000 protocol = "tcp" cidr_blocks = [var.allow_cidr] }
  egress  { from_port = 0    to_port = 0    protocol = "-1"  cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_instance" "lab_vm" {
  # ...
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
}

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = var.region
}

# Latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # Canonical
  most_recent = true
  filter { 
    name = "name" 
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] 
    }
  filter { 
    name = "virtualization-type" 
    values = ["hvm"] 
    }
}

resource "aws_key_pair" "lab" {
  key_name   = "ci-cd-lab-key"
  public_key = var.public_key
}

resource "aws_security_group" "lab_sg" {
  name        = "ci-cd-lab-sg"
  description = "Allow SSH, HTTP, Prometheus, Grafana"

  ingress { 
    from_port = 22   
    to_port = 22   
    protocol = "tcp" 
    cidr_blocks = [var.allow_cidr] 
    }
  ingress { 
    from_port = 80   
    to_port = 80   
    protocol = "tcp" 
    cidr_blocks = [var.allow_cidr] 
    }
  ingress { 
    from_port = 9090 
    to_port = 9090 
    protocol = "tcp" 
    cidr_blocks = [var.allow_cidr] 
    }
  ingress { 
    from_port = 3000 
    to_port = 3000 
    protocol = "tcp" 
    cidr_blocks = [var.allow_cidr] 
    }

  egress  { 
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
    }
}

resource "aws_instance" "lab_vm" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.lab.key_name
  vpc_security_group_ids = [aws_security_group.lab_sg.id]
  associate_public_ip_address = true

  tags = { Name = "ci-cd-lab-vm" }
}
