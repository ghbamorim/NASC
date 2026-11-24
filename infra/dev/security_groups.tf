resource "aws_security_group" "ec2" {
  name        = "nasc-dev-ec2-sg"
  description = "Security group for NASC dev EC2"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "nasc-dev-ec2-sg"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_security_group" "rds" {
  name        = "nasc-dev-rds-sg"
  description = "Security group for NASC dev RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Allow PostgreSQL from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = {
    Name        = "nasc-dev-rds-sg"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}