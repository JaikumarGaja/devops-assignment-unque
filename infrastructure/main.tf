terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# VPC for the Connection of EC2 and DocDB 
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

#subnet for the docdb (one server)
resource "aws_subnet" "docdb-aws_subnet-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
}

#subnet for the docdb (2nd server)
resource "aws_subnet" "docdb-aws_subnet-2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-south-1b"
}

#Docdb subnet pool 
resource "aws_docdb_subnet_group" "main" {
  name       = "docdb-subnet-group"
  subnet_ids = [aws_subnet.docdb-aws_subnet-1.id, aws_subnet.docdb-aws_subnet-2.id]
}

#ec2_subnet  
resource "aws_subnet" "ec2-aws_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.100.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.ec2-aws_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


resource "aws_security_group" "ec2-sg" {
  name        = "unque-assignment-ec2"
  description = "Allow SSH, Allow 4000 Port"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4000
    to_port     = 4000
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

resource "aws_security_group" "docdb-sg" {
  name        = "unque-assignment-docdb"
  description = "Allow EC2 connection to Doc DB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2-sg.id]
  }
}

# Ec2 Instance 
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "unque-sssignment" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = "unique-assignment"
  subnet_id              = aws_subnet.ec2-aws_subnet.id
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  tags = {
    Name = "unque-server"
  }
}

# Document DB 

resource "aws_docdb_cluster" "unque-docdb" {
  cluster_identifier     = "unque-docdb"
  engine                 = "docdb"
  master_username        = var.db_username
  master_password        = var.db_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.docdb-sg.id]
  db_subnet_group_name   = aws_docdb_subnet_group.main.name
}
