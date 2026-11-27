resource "aws_lambda_function" "telegram_send_message" {
  function_name = "${local.name_prefix}-telegram-send-message"
  role          = aws_iam_role.telegram_send_message.arn
  runtime       = "python3.14"
  handler       = "handler.lambda_handler"

  filename = "${path.module}/../../../lambdas/telegram-send-message/function.zip"

  source_code_hash = try(
    filebase64sha256("${path.module}/../../../lambdas/telegram-send-message/function.zip"),
    null
  )

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      SECRET_ID = aws_secretsmanager_secret.app.name
    }
  }

  depends_on = [
    aws_iam_role_policy.telegram_send_message
  ]
}

resource "aws_lambda_event_source_mapping" "telegram_send_message" {
  event_source_arn = aws_sqs_queue.telegram_outbound.arn
  function_name    = aws_lambda_function.telegram_send_message.arn

  batch_size = 1
  enabled    = true
}

resource "aws_lambda_function" "telegram_process_message" {
  function_name = "${local.name_prefix}-telegram-process-message"
  role          = aws_iam_role.telegram_process_message.arn
  runtime       = "python3.14"
  handler       = "handler.lambda_handler"

  filename = "${path.module}/../../../lambdas/telegram-process-message/function.zip"

  source_code_hash = try(
    filebase64sha256("${path.module}/../../../lambdas/telegram-process-message/function.zip"),
    null
  )

  memory_size = 128
  timeout     = 480

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
      SECRET_ID           = aws_secretsmanager_secret.app.name
      API_URL             = "http://${aws_instance.main.private_ip}:8000"
      OUTBOUND_QUEUE_URL  = aws_sqs_queue.telegram_outbound.url
      API_TIMEOUT_SECONDS = "450"
    }
  }

  depends_on = [
    aws_iam_role_policy.telegram_process_message,
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