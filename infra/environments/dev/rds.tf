resource "aws_db_subnet_group" "main" {
  name = "nasc-dev-db-subnets"

  subnet_ids = [
    aws_subnet.private.id,
    aws_subnet.private_secondary.id
  ]

  tags = {
    Name = "nasc-dev-db-subnets"
  }
}

resource "aws_db_instance" "postgres" {
  identifier = "nasc-dev-postgres"

  engine         = "postgres"
  instance_class = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = "nasc"
  username = "nasc_admin"

  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true

  apply_immediately = true

  tags = {
    Name = "nasc-dev-postgres"
  }
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "postgres_master_secret_arn" {
  value = aws_db_instance.postgres.master_user_secret[0].secret_arn
}
