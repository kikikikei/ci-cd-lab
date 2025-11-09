terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
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
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---- make names unique each run (prevents Duplicate errors in CI) ----
resource "random_id" "suffix" {
  byte_length = 2
}

resource "aws_key_pair" "lab" {
  key_name   = "ci-cd-lab-key-${random_id.suffix.hex}"
  public_key = var.public_key
}

resource "aws_security_group" "lab_sg" {
  name        = "ci-cd-lab-sg-${random_id.suffix.hex}"
  description = "Allow SSH, HTTP, Prometheus, Grafana"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allow_cidr]
  }

  ingress {
    description = "App HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allow_cidr]
  }

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.allow_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allow_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "lab_vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.lab.key_name
  vpc_security_group_ids      = [aws_security_group.lab_sg.id]
  associate_public_ip_address = true

  # ---- cloud-init: preinstall Docker + Compose v2 so Ansible passes ----
  user_data = <<-EOF
  #cloud-config
  package_update: true
  packages:
    - ca-certificates
    - curl
    - gnupg
    - lsb-release
  runcmd:
    - install -m 0755 -d /etc/apt/keyrings
    - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    - chmod a+r /etc/apt/keyrings/docker.gpg
    - bash -lc 'source /etc/os-release && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${UBUNTU_CODENAME} stable" > /etc/apt/sources.list.d/docker.list'
    - apt-get update
    - apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    - systemctl enable --now docker
  EOF

  tags = { Name = "ci-cd-lab-vm" }
}
