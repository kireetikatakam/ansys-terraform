provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "tfstate"
    key    = "app-state"
    region = "us-west-2"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidr_blocks)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr_blocks[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidr_blocks)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr_blocks)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "http_sg" {
  name        = "http_sg"
  description = "Security group for HTTP traffic to port 80"
  vpc_id      = aws_vpc.this.id

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

resource "aws_instance" "nginx" {
  ami                         = "ami-0000000000000"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.http_sg.id]
  associate_public_ip_address = true

  tags = {
    Service = "nginx"
  }
}