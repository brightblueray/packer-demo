terraform {
  cloud {
    organization = "brightblueray"
    workspaces {
      name = "hcp-packer-demo-dev"
    }
  }

  required_providers {

    aws = {
      source = "hashicorp/aws"
    }

    hcp = {
      source = "hashicorp/hcp"
    }

  }
}

provider "hcp" {}

data "hcp_packer_image" "ubuntu" {
  bucket_name    = "hashicups-frontend-ubuntu"
  channel        = "dev"
  cloud_provider = "aws"
  region         = "us-east-2"
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "hashicups_frontend" {
  ami                         = data.hcp_packer_image.ubuntu.cloud_image_id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subnet_public.id
  vpc_security_group_ids      = [aws_security_group.sg_22_80.id]
  associate_public_ip_address = true

  tags = {
    Name = "hashicups-frontend"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "subnet_public" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.cidr_subnet
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_security_group" "sg_22_80" {
  name   = "sg_22_80"
  vpc_id = aws_vpc.vpc.id

  # SSH access from the VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

output "app_url" {
  value = "http://${aws_instance.hashicups_frontend.public_ip}"
}
