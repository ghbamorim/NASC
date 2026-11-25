resource "aws_sqs_queue" "telegram_inbound" {
  name                        = "telegram-inbound.fifo"
  fifo_queue                  = true
  content_based_deduplication = false

  visibility_timeout_seconds = 720
  message_retention_seconds  = 345600
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.telegram_inbound_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "telegram_outbound" {
  name                        = "telegram-outbound.fifo"
  fifo_queue                  = true
  content_based_deduplication = false

  visibility_timeout_seconds = 180
  message_retention_seconds  = 345600
  sqs_managed_sse_enabled    = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.telegram_outbound_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "telegram_inbound_dlq" {
  name                      = "telegram-inbound-dlq.fifo"
  fifo_queue                = true
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}

resource "aws_sqs_queue" "telegram_outbound_dlq" {
  name                      = "telegram-outbound-dlq.fifo"
  fifo_queue                = true
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true
}