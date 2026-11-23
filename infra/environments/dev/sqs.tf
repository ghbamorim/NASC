resource "aws_sqs_queue" "messages_dlq" {
  name                      = "nasc-dev-messages-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "messages" {
  name                       = "nasc-dev-messages"
  visibility_timeout_seconds = 180
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.messages_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "messages_dlq" {
  queue_url = aws_sqs_queue.messages_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.messages.arn]
  })
}

output "messages_queue_url" {
  description = "URL of the incoming messages queue"
  value       = aws_sqs_queue.messages.url
}

output "messages_queue_arn" {
  description = "ARN of the incoming messages queue"
  value       = aws_sqs_queue.messages.arn
}

output "messages_dlq_arn" {
  description = "ARN of the dead-letter queue"
  value       = aws_sqs_queue.messages_dlq.arn
}

resource "aws_sqs_queue" "telegram_outgoing_dlq" {
  name                      = "nasc-dev-telegram-outgoing-dlq"
  message_retention_seconds = 1209600
}

resource "aws_sqs_queue" "telegram_outgoing" {
  name                       = "nasc-dev-telegram-outgoing"
  visibility_timeout_seconds = 180
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 20

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.telegram_outgoing_dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "telegram_outgoing_dlq" {
  queue_url = aws_sqs_queue.telegram_outgoing_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.telegram_outgoing.arn]
  })
}

output "telegram_outgoing_queue_url" {
  value = aws_sqs_queue.telegram_outgoing.url
}

output "telegram_outgoing_queue_arn" {
  value = aws_sqs_queue.telegram_outgoing.arn
}