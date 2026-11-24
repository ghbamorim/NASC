resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "nasc-dev-igw"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}