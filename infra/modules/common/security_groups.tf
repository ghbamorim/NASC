resource "aws_security_group" "ec2" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "Security group for NASC ${var.environment} EC2"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Security group for NASC ${var.environment} RDS"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rds-sg"
  }
}

resource "aws_security_group" "telegram_process_message" {
  name        = "${local.name_prefix}-telegram-process-message-sg"
  description = "Security group for Telegram processing Lambda"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-telegram-process-message-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_nat_https" {
  for_each = {
    private_a = aws_subnet.private_a.cidr_block
    private_b = aws_subnet.private_b.cidr_block
  }

  security_group_id = aws_security_group.ec2.id
  description       = "Allow HTTPS traffic for NAT"
  cidr_ipv4         = each.value
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = {
    Name = "${local.name_prefix}-ec2-nat-https-${each.key}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ec2_fastapi" {
  security_group_id            = aws_security_group.ec2.id
  referenced_security_group_id = aws_security_group.telegram_process_message.id
  description                  = "Allow FastAPI access from Lambda"
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"

  tags = {
    Name = "${local.name_prefix}-ec2-fastapi"
  }
}

resource "aws_vpc_security_group_egress_rule" "ec2_outbound" {
  security_group_id = aws_security_group.ec2.id
  description       = "Allow outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    Name = "${local.name_prefix}-ec2-outbound"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.ec2.id
  description                  = "Allow PostgreSQL from EC2"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  tags = {
    Name = "${local.name_prefix}-rds-postgres"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_https" {
  security_group_id = aws_security_group.telegram_process_message.id
  description       = "Allow HTTPS to AWS services"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"

  tags = {
    Name = "${local.name_prefix}-lambda-https"
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_fastapi" {
  security_group_id            = aws_security_group.telegram_process_message.id
  referenced_security_group_id = aws_security_group.ec2.id
  description                  = "Allow access to FastAPI"
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"

  tags = {
    Name = "${local.name_prefix}-lambda-fastapi"
  }
}