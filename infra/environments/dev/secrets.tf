resource "aws_secretsmanager_secret" "telegram_bot_token" {
  name = "nasc/dev/telegram/bot-token"

  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret" "telegram_webhook_secret" {
  name = "nasc/dev/telegram/webhook-secret"

  recovery_window_in_days = 7
}

output "telegram_bot_token_secret_arn" {
  value = aws_secretsmanager_secret.telegram_bot_token.arn
}

output "telegram_webhook_secret_arn" {
  value = aws_secretsmanager_secret.telegram_webhook_secret.arn
}