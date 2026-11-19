resource "aws_cloudwatch_log_group" "app" {
  name              = "/nasc/dev/app"
  retention_in_days = 7
}