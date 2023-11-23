# The required version and provider for AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }
  }

  required_version = ">= 1.2.0"

}

provider "aws" {
  region     = "eu-north-1"
  access_key = var.access_key
  secret_key = var.secret_key
}


# Create VPC
resource "aws_vpc" "nginx_vpc" {

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "nginx_vpc"
    Description = "This is a VPC for nginx application"
  }
}

# create an EIP for NAT gateway
resource "aws_eip" "EIP_NAT" {
  #   vpc = true

  tags = {
    Name        = "EIP-for-NAT"
    Description = "EIP assigned to NAT gateway"
  }
}

# Create the NAT gateway
resource "aws_nat_gateway" "nginx_nat_gateway" {
  allocation_id = aws_eip.EIP_NAT.id
  subnet_id     = aws_subnet.nginx_public_subnet1.id

  tags = {
    Name        = "nginx-nat-gateway"
    Description = "nginx-nat-gateway"
  }
}

# Create a route table for the private subnet   
resource "aws_route_table" "nginx_route_table_nat" {
  vpc_id = aws_vpc.nginx_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nginx_nat_gateway.id
  }

  tags = {
    Name = "Private Route Table for nat"
  }
}

# Create internet gateway for public subnet
resource "aws_internet_gateway" "nginx_igw" {
  vpc_id = aws_vpc.nginx_vpc.id

  tags = {
    Name        = "nginx_IGW"
    Description = "This is a IGW for the public subnets"
  }
}


# Create route table routed to IGW for public subnets 1 and 2 
resource "aws_route_table" "nginx_route_table_igw" {
  vpc_id = aws_vpc.nginx_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nginx_igw.id
  }

  tags = {
    Name        = "nginx_route_table_igw"
    Description = "nginx route table igw"
  }
}

# Create private subnet 1
resource "aws_subnet" "nginx_private_subnet1" {
  vpc_id            = aws_vpc.nginx_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name = "nginx_private_subnet1"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "nginx_route_table_nat" {
  route_table_id = aws_route_table.nginx_route_table_nat.id
  subnet_id      = aws_subnet.nginx_private_subnet1.id
}

# Create private subnet 2
resource "aws_subnet" "nginx_private_subnet2" {
  vpc_id            = aws_vpc.nginx_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name = "nginx_private_subnet2"
  }
}

# Associate the private route table with the private subnet
resource "aws_route_table_association" "nginx_private_association2" {
  route_table_id = aws_route_table.nginx_route_table_nat.id
  subnet_id      = aws_subnet.nginx_private_subnet2.id
}

# Create public subnet 1
resource "aws_subnet" "nginx_public_subnet1" {
  vpc_id            = aws_vpc.nginx_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-north-1a"

  tags = {
    Name        = "nginx_public_subnet1"
    Description = "This is a public subnet 1 for ec2 1"
  }
}

# Associate public subnet 1 with the route table
resource "aws_route_table_association" "public_subnet_assoc1" {
  subnet_id      = aws_subnet.nginx_public_subnet1.id
  route_table_id = aws_route_table.nginx_route_table_igw.id
}


# Create public subnet 2
resource "aws_subnet" "nginx_public_subnet2" {
  vpc_id            = aws_vpc.nginx_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-north-1b"

  tags = {
    Name        = "nginx_public_subnet2"
    Description = "This is a public subnet 2 for ec2 1"
  }
}

# Associate public subnet 2 with the route table
resource "aws_route_table_association" "public_subnet_assoc2" {
  subnet_id      = aws_subnet.nginx_public_subnet2.id
  route_table_id = aws_route_table.nginx_route_table_igw.id
}

resource "aws_key_pair" "key_pair" {
  key_name   = "key-pair"
  public_key = file("~/.ssh/key-pair.pub")
}

# create a ec2 1
resource "aws_instance" "nginx_ec2" {
  ami                         = "ami-0416c18e75bd69567" #amazon linux 2
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.key_pair.key_name
  subnet_id                   = aws_subnet.nginx_public_subnet1.id
  vpc_security_group_ids      = [aws_security_group.ec2_security_group.id]
  associate_public_ip_address = true
  tags = {
    Name = "nginx_ec2"

  }
}

# create ec2 security group
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Allow SSH access to ec2 from my local pc"
  vpc_id      = aws_vpc.nginx_vpc.id


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
    Name        = "ec2_security_group"
    Description = "security group for 2nd ec2"
  }
}



# create a sg to elb 
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = aws_vpc.nginx_vpc.id

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

  tags = {
    Name = "alb_sg"
  }
}

# create LB to enter the ec2 
resource "aws_lb" "nginx_elb" {
  name               = "nginxELB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.nginx_public_subnet1.id, aws_subnet.nginx_public_subnet2.id]
  tags = {
    Name = "nginx_elb"
  }
}

resource "aws_lb_listener" "nginx_lb_listener" {
  load_balancer_arn = aws_lb.nginx_elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_lb_nginx.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "target_group_lb_nginx" {
  name                 = "LB-targetGroup"
  port                 = "8000"
  protocol             = "HTTP"
  vpc_id               = aws_vpc.nginx_vpc.id
  deregistration_delay = 30

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = "/"
    matcher             = "200"
  }
}

