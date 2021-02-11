// Gets all available AZs for the chosen region
data "aws_availability_zones" "available" {}

locals {
  count = length(data.aws_availability_zones.available.names)
}

// Creates the VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
      Name = "GA_VPC"
  }

}

// Creates one private subnet for each AZ
resource "aws_subnet" "private-subnets" {
  count             = local.count
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.main.id

  tags = {
      Name = "Private Subnet"
  }

}

// Creates one public subnet for each AZ
resource "aws_subnet" "public-subnets" {
  count                   = local.count
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, local.count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.main.id
  map_public_ip_on_launch = true

  tags = {
      Name = "Public Subnet"
  }
}

// Internet Gateway for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

// Routes public subnet traffic through the IGW
resource "aws_route" "internet-access" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

// Create a NAT gateway with an Elastic IP for each private subnet to get internet connectivity
resource "aws_eip" "nat-eip" {
  count      = local.count
  vpc        = true
  depends_on = [aws_internet_gateway.igw]

}

resource "aws_nat_gateway" "nat-gw" {
  count         = local.count
  subnet_id     = element(aws_subnet.public-subnets.*.id, count.index)
  allocation_id = element(aws_eip.nat-eip.*.id, count.index)
}

// Create a route table for the private subnets and make it route non-local traffic through the NAT gateway to the internet
resource "aws_route_table" "private" {
  count  = local.count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat-gw.*.id, count.index)
  }
}

// Replace the default route table association with the new route table
resource "aws_route_table_association" "private" {
  count          = local.count
  subnet_id      = element(aws_subnet.private-subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}
