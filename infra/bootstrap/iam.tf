locals {
  policy_names = toset([
    "backend",
    "ec2",
    "ec2-integrations",
    "ecr",
    "ecr-sharing",
    "iam",
    "rds",
    "secrets",
    "ssm",
    "cloudwatch",
    "cloudwatch-composite",
    "lambda"
  ])

  attached_policy_names = toset([
    "backend",
    "ec2",
    "ecr",
    "iam",
    "rds",
    "secrets",
    "ssm",
    "cloudwatch"

    # Future integrations requiring security review.
    # "ec2-integrations",
    # "ecr-sharing",
    # "cloudwatch-composite",
    # "lambda"
  ])
}

resource "aws_iam_user" "nasc_terraform" {
  name = "nasc_terraform"
  path = "/"
}

resource "aws_iam_policy" "nasc_terraform_service" {
  for_each = local.policy_names

  name   = "nasc-terraform-${each.key}-policy"
  policy = file("${path.module}/policies/${each.key}.json")
}

resource "aws_iam_user_policy_attachment" "nasc_terraform_service" {
  for_each = local.attached_policy_names

  user       = aws_iam_user.nasc_terraform.name
  policy_arn = aws_iam_policy.nasc_terraform_service[each.key].arn
}