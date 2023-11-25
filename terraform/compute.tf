
# Create the NAT gateway
resource "aws_nat_gateway" "nginx_nat_gateway" {
  allocation_id = aws_eip.EIP_NAT.id
  subnet_id     = aws_subnet.nginx_public_subnet1.id

  tags = {
    Name        = "nginx-nat-gateway"
    Description = "nginx-nat-gateway"
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

