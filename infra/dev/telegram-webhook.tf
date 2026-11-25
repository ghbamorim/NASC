resource "aws_lambda_function" "telegram_receive_message" {
  function_name = "nasc-dev-telegram-receive-message"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/nasc-dev-telegram-receive-message"
  runtime       = "python3.14"
  handler       = "handler.lambda_handler"

  filename         = "${path.module}/../../lambdas/telegram-receive-message/function.zip"
  source_code_hash = try(filebase64sha256("${path.module}/../../lambdas/telegram-receive-message/function.zip"), null)

  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      SECRET_ID         = "nasc/dev/app"
      INBOUND_QUEUE_URL = aws_sqs_queue.telegram_inbound.url
    }
  }
}

resource "aws_apigatewayv2_api" "telegram" {
  name          = "nasc-dev-telegram"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "telegram_webhook" {
  api_id = aws_apigatewayv2_api.telegram.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.telegram_receive_message.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "telegram_webhook" {
  api_id = aws_apigatewayv2_api.telegram.id

  route_key = "POST /telegram/webhook"
  target    = "integrations/${aws_apigatewayv2_integration.telegram_webhook.id}"
}

resource "aws_apigatewayv2_stage" "telegram" {
  api_id      = aws_apigatewayv2_api.telegram.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 20
    throttling_rate_limit  = 10
  }
}

resource "aws_lambda_permission" "telegram_webhook" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telegram_receive_message.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.telegram.execution_arn}/*/POST/telegram/webhook"
}

output "telegram_webhook_url" {
  value = "${aws_apigatewayv2_api.telegram.api_endpoint}/telegram/webhook"
}