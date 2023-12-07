provider "aws" {
  region = "ap-south-1"  # Specify your desired AWS region
}

# Create a VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block = "10.0.0.0/16"  # Specify the CIDR block for your VPC

  tags = {
    Name = "devops_vpc"
  }
}

# Create a public subnet within the VPC
resource "aws_subnet" "devops_public_subnet" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = "10.0.0.0/24"  # Specify the CIDR block for your public subnet
  availability_zone       = "ap-south-1a"   # Specify the desired availability zone

  map_public_ip_on_launch = true  # This enables auto-assignment of public IP addresses

  tags = {
    Name = "devops_public_subnet"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "devops_igw" {
  vpc_id = aws_vpc.devops_vpc.id

  tags = {
    Name = "devops_igw"
  }
}

# Create a route table for the public subnet
resource "aws_route_table" "devops-public-route-table" {
  vpc_id = aws_vpc.devops_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_igw.id
  }

  tags = {
    Name = "devops-public-route-table"
  }
}

# Associate the public subnet with the public route table
resource "aws_route_table_association" "devops_public_rta" {
  subnet_id      = aws_subnet.devops_public_subnet.id
  route_table_id = aws_route_table.devops-public-route-table.id
}

# Create a security group
resource "aws_security_group" "devops_sc" {
  vpc_id = aws_vpc.devops_vpc.id

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
    Name = "devops_sc"
  }
}

# Define a list of instance names
variable "instance_names" {
  default = ["Jenkins master", "Build node", "Ansible node"]
}

# Create an EC2 instance within the public subnet
resource "aws_instance" "example" {

  count = length(var.instance_names)
  ami           = "ami-0a7cf821b91bcccbc"  # Amazon Linux 2 AMI (replace with your desired AMI)
  instance_type = "t2.micro"               # Instance type (you can change it as needed)
  subnet_id     = aws_subnet.devops_public_subnet.id   # Specify the public subnet for the instance
  key_name      = "mumbai"    # Replace with your key pair name
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.devops_sc.id]

  tags = {
    Name = var.instance_names[count.index]
  }
}
