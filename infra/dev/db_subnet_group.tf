resource "aws_db_subnet_group" "main" {
  name        = "nasc-dev-db-subnet-group"
  description = "Subnet group for NASC dev RDS"

  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]

  tags = {
    Name        = "nasc-dev-db-subnet-group"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}