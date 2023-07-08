resource "aws_vpc" "dev" {
    cidr_block = "10.0.0.0/16"
    tags = {
        "Name"= "new"
        project= "sprints-new"
    }
}
resource "aws_subnet" "terraform_subnet" {
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.dev.id
    map_public_ip_on_launch = true
     tags = {
        Name = "terraform_subnet"
    }
}
resource "aws_internet_gateway" "terraform_IGW" {
  vpc_id = aws_vpc.dev.id
    tags = {
    Name = "terraform_IGW"
  }
}
resource "aws_route_table" "terraform_routeTable" {
  vpc_id = aws_vpc.dev.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform_IGW.id
  }
   tags = {
    Name = "terraform_routeTable"
  }
}
resource "aws_route_table_association" "terraform_routeTable_association" {
  subnet_id      = aws_subnet.terraform_subnet.id
  route_table_id = aws_route_table.terraform_routeTable.id
}
resource "aws_security_group" "terraform_securityGroup" {
  name        = "terraform_securityGroup"
  description = "Allow HTTP and SSH traffic"
  vpc_id = aws_vpc.dev.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTPS connections"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming HTTP connections"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }
  tags = {
    Name = "terraform_securityGroup"
  }
}
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_instance" "terraform_instance" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.terraform_subnet.id
  vpc_security_group_ids      = [aws_security_group.terraform_securityGroup.id]
  associate_public_ip_address = true
  source_dest_check           = false
  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y apache2
  EOF

  tags = {
    Name = "terraform_instance"
  }
}

