resource "aws_sqs_queue" "telegram_inbound" {
  name                        = "telegram-inbound.fifo"
  fifo_queue                  = true
  content_based_deduplication = false

  visibility_timeout_seconds = 2880
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

resource "aws_sqs_queue_redrive_allow_policy" "telegram_inbound_dlq" {
  queue_url = aws_sqs_queue.telegram_inbound_dlq.url

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.telegram_inbound.arn]
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "telegram_outbound_dlq" {
  queue_url = aws_sqs_queue.telegram_outbound_dlq.url

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.telegram_outbound.arn]
  })
}