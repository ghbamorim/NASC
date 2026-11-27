resource "aws_secretsmanager_secret" "app" {
  name                    = "nasc/${var.environment}/app"
  description             = "NASC ${var.environment} application secrets"
  recovery_window_in_days = 7

  tags = {
    Name = "${local.name_prefix}-app-secret"
  }
}

output "app_secret_arn" {
  value = aws_secretsmanager_secret.app.arn
}