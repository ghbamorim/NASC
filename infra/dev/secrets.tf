resource "aws_secretsmanager_secret" "app" {
  name                    = "nasc/dev/app"
  description             = "NASC dev application secrets"
  recovery_window_in_days = 7

  tags = {
    Name        = "nasc-dev-app-secret"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

output "app_secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}