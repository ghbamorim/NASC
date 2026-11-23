resource "aws_secretsmanager_secret" "backend_config" {
  name                    = "nasc/dev/backend/config"
  recovery_window_in_days = 7
}

output "backend_config_secret_arn" {
  value = aws_secretsmanager_secret.backend_config.arn
}
