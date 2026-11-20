resource "aws_apigatewayv2_api" "telegram" {
  name          = "nasc-dev-telegram"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "telegram_webhook" {
  api_id = aws_apigatewayv2_api.telegram.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.telegram_webhook.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "telegram_webhook" {
  api_id = aws_apigatewayv2_api.telegram.id

  route_key = "POST /webhooks/telegram"

  target = "integrations/${aws_apigatewayv2_integration.telegram_webhook.id}"
}

resource "aws_apigatewayv2_stage" "telegram" {
  api_id      = aws_apigatewayv2_api.telegram.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "telegram_api_gateway" {
  statement_id  = "AllowTelegramApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.telegram_webhook.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.telegram.execution_arn}/*/POST/webhooks/telegram"
}

output "telegram_webhook_url" {
  description = "Telegram webhook HTTPS endpoint"
  value       = "${aws_apigatewayv2_api.telegram.api_endpoint}/webhooks/telegram"
}
