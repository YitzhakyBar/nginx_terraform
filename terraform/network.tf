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


