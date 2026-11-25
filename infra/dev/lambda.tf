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

resource "aws_lambda_function" "telegram_process_message" {
  function_name = "nasc-dev-telegram-process-message"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nasc-dev-telegram-process-message"
  runtime       = "python3.14"
  handler       = "handler.lambda_handler"

  filename         = "${path.module}/../../lambdas/telegram-process-message/function.zip"
  source_code_hash = try(filebase64sha256("${path.module}/../../lambdas/telegram-process-message/function.zip"), null)

  memory_size = 128
  timeout     = 150

  vpc_config {
    subnet_ids = [
      aws_subnet.private_a.id
    ]

    security_group_ids = [
      aws_security_group.telegram_process_message.id
    ]
  }

  environment {
    variables = {
      SECRET_ID          = "nasc/dev/app"
      API_URL            = "http://${aws_instance.main.private_ip}:8000"
      OUTBOUND_QUEUE_URL = aws_sqs_queue.telegram_outbound.url
    }
  }

  depends_on = [
    aws_route.private_nat,
    aws_vpc_security_group_egress_rule.lambda_https,
    aws_vpc_security_group_egress_rule.lambda_fastapi
  ]
}

resource "aws_lambda_event_source_mapping" "telegram_process_message" {
  event_source_arn = aws_sqs_queue.telegram_inbound.arn
  function_name    = aws_lambda_function.telegram_process_message.arn
  batch_size       = 1
  enabled          = true
}