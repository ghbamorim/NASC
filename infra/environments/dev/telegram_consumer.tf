data "archive_file" "telegram_consumer" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/telegram_consumer"
  output_path = "${path.module}/telegram_consumer.zip"
}

resource "aws_iam_role" "telegram_consumer" {
  name = "nasc-dev-telegram-consumer"

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

resource "aws_iam_role_policy" "telegram_consumer" {
  name = "nasc-dev-telegram-consumer"
  role = aws_iam_role.telegram_consumer.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ConsumeMessages"
        Effect = "Allow"

        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]

        Resource = aws_sqs_queue.messages.arn
      },
      {
        Sid    = "ManageVpcNetworkInterfaces"
        Effect = "Allow"

        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]

        Resource = "*"
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.telegram_consumer.arn}:*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "telegram_consumer" {
  name              = "/aws/lambda/nasc-dev-telegram-consumer"
  retention_in_days = 7
}

resource "aws_lambda_function" "telegram_consumer" {
  function_name = "nasc-dev-telegram-consumer"

  role    = aws_iam_role.telegram_consumer.arn
  runtime = "python3.14"
  handler = "handler.lambda_handler"

  filename         = data.archive_file.telegram_consumer.output_path
  source_code_hash = data.archive_file.telegram_consumer.output_base64sha256

  timeout     = 150
  memory_size = 128

  vpc_config {
    subnet_ids = [
      aws_subnet.private.id,
      aws_subnet.private_secondary.id
    ]

    security_group_ids = [
      aws_security_group.telegram_consumer.id
    ]
  }

  environment {
    variables = {
      FASTAPI_URL = "http://${aws_instance.backend.private_ip}:8000"
    }
  }

  depends_on = [
    aws_iam_role_policy.telegram_consumer,
    aws_cloudwatch_log_group.telegram_consumer
  ]
}

resource "aws_lambda_event_source_mapping" "telegram_consumer" {
  event_source_arn = aws_sqs_queue.messages.arn
  function_name    = aws_lambda_function.telegram_consumer.arn

  batch_size = 1

  function_response_types = [
    "ReportBatchItemFailures"
  ]

  enabled = true
}