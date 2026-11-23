resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "nasc-dev-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "nasc-dev-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "nasc-dev-public"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "nasc-dev-private"
  }
}

resource "aws_subnet" "private_secondary" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.3.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "nasc-dev-private-secondary"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "nasc-dev-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "nasc-dev-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_secondary" {
  subnet_id      = aws_subnet.private_secondary.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "fastapi" {
  name        = "nasc-dev-fastapi"
  description = "Network access to NASC FastAPI"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "nasc-dev-fastapi-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "fastapi_https" {
  security_group_id = aws_security_group.fastapi.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"

  description = "HTTPS access for AWS services and Gemini"
}

resource "aws_vpc_security_group_egress_rule" "fastapi_http" {
  security_group_id = aws_security_group.fastapi.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"

  description = "HTTP access for initial package installation"
}

# Lambda consumidora: acesso privado ao FastAPI

resource "aws_security_group" "telegram_consumer" {
  name        = "nasc-dev-telegram-consumer"
  description = "Network access for Telegram consumer Lambda"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "nasc-dev-telegram-consumer-sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "consumer_to_fastapi" {
  security_group_id            = aws_security_group.telegram_consumer.id
  referenced_security_group_id = aws_security_group.fastapi.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000

  description = "Private HTTP access to FastAPI"
}

resource "aws_vpc_security_group_ingress_rule" "fastapi_from_consumer" {
  security_group_id            = aws_security_group.fastapi.id
  referenced_security_group_id = aws_security_group.telegram_consumer.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000

  description = "FastAPI access from Telegram consumer Lambda"
}

resource "aws_security_group" "rds" {
  name        = "nasc-dev-rds"
  description = "PostgreSQL access from NASC FastAPI"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "nasc-dev-rds-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_fastapi" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.fastapi.id

  ip_protocol = "tcp"
  from_port   = 5432
  to_port     = 5432

  description = "PostgreSQL from FastAPI"
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "fastapi_security_group_id" {
  value = aws_security_group.fastapi.id
}

output "telegram_consumer_security_group_id" {
  value = aws_security_group.telegram_consumer.id
}