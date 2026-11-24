variable "db_password" {
  type      = string
  sensitive = true
  ephemeral = true
}

resource "aws_db_instance" "main" {
  identifier = "nasc-dev-postgres"

  engine         = "postgres"
  engine_version = "17"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "nasc"
  username = "nasc_admin"

  password_wo         = var.db_password
  password_wo_version = 1

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  tags = {
    Name        = "nasc-dev-postgres"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

output "db_endpoint" {
  value = aws_db_instance.main.address
}