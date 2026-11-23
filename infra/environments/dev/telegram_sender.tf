data "archive_file" "telegram_sender" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/telegram_sender"
  output_path = "${path.module}/telegram_sender.zip"
}

resource "aws_iam_role" "telegram_sender" {
  name = "nasc-dev-telegram-sender"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"

        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "telegram_sender" {
  name              = "/aws/lambda/nasc-dev-telegram-sender"
  retention_in_days = 7
}

resource "aws_iam_role_policy" "telegram_sender" {
  name = "nasc-dev-telegram-sender"
  role = aws_iam_role.telegram_sender.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ConsumeOutgoingMessages"
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = aws_sqs_queue.telegram_outgoing.arn
      },
      {
        Sid    = "ReadTelegramBotToken"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_secretsmanager_secret.telegram_bot_token.arn
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.telegram_sender.arn}:*"
      }
    ]
  })
}

resource "aws_lambda_function" "telegram_sender" {
  function_name = "nasc-dev-telegram-sender"

  role    = aws_iam_role.telegram_sender.arn
  runtime = "python3.14"
  handler = "handler.lambda_handler"

  filename         = data.archive_file.telegram_sender.output_path
  source_code_hash = data.archive_file.telegram_sender.output_base64sha256

  timeout     = 30
  memory_size = 128

  environment {
    variables = {
      TELEGRAM_BOT_TOKEN_SECRET_ARN = aws_secretsmanager_secret.telegram_bot_token.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.telegram_sender,
    aws_cloudwatch_log_group.telegram_sender
  ]
}

resource "aws_lambda_event_source_mapping" "telegram_sender" {
  event_source_arn = aws_sqs_queue.telegram_outgoing.arn
  function_name    = aws_lambda_function.telegram_sender.arn

  batch_size = 1

  function_response_types = [
    "ReportBatchItemFailures"
  ]

  enabled = true
}