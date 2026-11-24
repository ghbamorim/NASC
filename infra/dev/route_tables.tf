resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "nasc-dev-public-rt"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "nasc-dev-private-rt"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}