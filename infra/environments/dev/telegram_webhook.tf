data "archive_file" "telegram_webhook" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/telegram_webhook"
  output_path = "${path.module}/telegram_webhook.zip"
}

resource "aws_iam_role" "telegram_webhook" {
  name = "nasc-dev-telegram-webhook"

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

resource "aws_iam_role_policy" "telegram_webhook" {
  name = "nasc-dev-telegram-webhook"
  role = aws_iam_role.telegram_webhook.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "PublishMessages"
        Effect = "Allow"

        Action = [
          "sqs:SendMessage"
        ]

        Resource = aws_sqs_queue.messages.arn
      },
      {
        Sid    = "ReadWebhookSecret"
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = aws_secretsmanager_secret.telegram_webhook_secret.arn
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.telegram_webhook.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "telegram_webhook" {
  name              = "/aws/lambda/nasc-dev-telegram-webhook"
  retention_in_days = 7
}

resource "aws_lambda_function" "telegram_webhook" {
  function_name = "nasc-dev-telegram-webhook"

  role    = aws_iam_role.telegram_webhook.arn
  runtime = "python3.14"
  handler = "handler.lambda_handler"

  filename         = data.archive_file.telegram_webhook.output_path
  source_code_hash = data.archive_file.telegram_webhook.output_base64sha256

  timeout     = 10
  memory_size = 128

  environment {
    variables = {
      QUEUE_URL          = aws_sqs_queue.messages.url
      WEBHOOK_SECRET_ARN = aws_secretsmanager_secret.telegram_webhook_secret.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.telegram_webhook,
    aws_cloudwatch_log_group.telegram_webhook
  ]
}