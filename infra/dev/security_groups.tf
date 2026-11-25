resource "aws_security_group" "ec2" {
  name        = "nasc-dev-ec2-sg"
  description = "Security group for NASC dev EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTPS traffic for NAT"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"

    cidr_blocks = [
      aws_subnet.private_a.cidr_block,
      aws_subnet.private_b.cidr_block
    ]
  }

  ingress {
    description     = "Allow FastAPI access from Lambda"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.telegram_process_message.id]
  }

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

resource "aws_security_group" "telegram_process_message" {
  name        = "nasc-dev-telegram-process-message-sg"
  description = "Security group for Telegram processing Lambda"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "nasc-dev-telegram-process-message-sg"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_https" {
  security_group_id = aws_security_group.telegram_process_message.id
  description       = "Allow HTTPS to AWS services"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "lambda_fastapi" {
  security_group_id            = aws_security_group.telegram_process_message.id
  referenced_security_group_id = aws_security_group.ec2.id
  description                  = "Allow access to FastAPI"
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
}