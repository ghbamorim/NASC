output "db_endpoint" {
  value = module.common.db_endpoint
}

output "app_secret_arn" {
  value = module.common.app_secret_arn
}

output "ec2_instance_id" {
  value = module.common.ec2_instance_id
}

output "telegram_webhook_url" {
  value = module.common.telegram_webhook_url
}