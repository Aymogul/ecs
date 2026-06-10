# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# Create VPC
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
  }
}

# Create public subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.env}-public-subnet-${count.index}"
    Environment = var.env
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.env}-private-subnet-${count.index}"
    Environment = var.env
  }
}

# Create NAT Gateway
resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.env}-nat-gateway"
    Environment = var.env
  }

  depends_on = [aws_internet_gateway.this]
}

# Create route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = var.vpc_cidr
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name        = "${var.env}-private-route-table"
    Environment = var.env
  }
}

