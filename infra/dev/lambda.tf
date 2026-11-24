resource "aws_lambda_function" "telegram_send_message" {
  function_name = "nasc-dev-telegram-send-message"

  role = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nasc-dev-telegram-send-message"

  runtime = "python3.14"
  handler = "handler.lambda_handler"

  filename = "${path.module}/../../lambdas/telegram-send-message/function.zip"
  source_code_hash = try(
    filebase64sha256("${path.module}/../../lambdas/telegram-send-message/function.zip"),
    null
  )

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      SECRET_ID = "nasc/dev/app"
    }
  }
}

resource "aws_lambda_event_source_mapping" "telegram_send_message" {
  event_source_arn = aws_sqs_queue.telegram_outbound.arn
  function_name    = aws_lambda_function.telegram_send_message.arn

  batch_size = 1
  enabled    = true
}