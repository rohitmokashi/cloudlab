data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block

  tags = {
    Name = "cloudlab VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, 0)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_internet_gateway" "internet_gw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = var.ig_name
 }
}

resource "aws_route_table" "internet_access_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.internet_gw.id
 }
 
 tags = {
   Name = "Internet Access Route Table"
 }
}

resource "aws_route_table_association" "public_subnet_asso" {
 subnet_id      = aws_subnet.public.id
 route_table_id = aws_route_table.internet_access_rt.id
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, 1)
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_eip" "ip" {}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.ip.id
  subnet_id = aws_subnet.public.id
  tags = {
    "Name" = "Private NAT Gateway"
  }
}

resource "aws_route_table" "private_internet_access_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_subnet_asso" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private_internet_access_rt.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}
