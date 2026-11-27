locals {
  policy_names = toset([
    "backend",
    "ec2",
    "ecr",
    "iam",
    "rds",
    "secrets",
    "ssm",
    "cloudwatch",
    "lambda",
    "sqs",
    "apigateway"
  ])

  attached_policy_names = toset([
    "backend",
    "ec2",
    "ecr",
    "iam",
    "rds",
    "secrets",
    "ssm",
    "cloudwatch",
    "sqs",
    "lambda",
    "apigateway"
  ])

  policy_combinations = {
    for pair in setproduct(
      local.environments,
      local.policy_names
      ) : "${pair[0]}-${pair[1]}" => {
      environment = pair[0]
      policy_name = pair[1]
    }
  }

  attachment_combinations = {
    for key, value in local.policy_combinations :
    key => value
    if contains(local.attached_policy_names, value.policy_name)
  }
}

resource "aws_iam_role" "nasc_terraform" {
  for_each = local.environments

  name = "nasc-${each.key}-terraform"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            "token.actions.githubusercontent.com:sub" = "repo:ghbamorim@79848031/NASC@1455266988:environment:${each.key}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "nasc_terraform_service" {
  for_each = local.policy_combinations

  name = "nasc-${each.key}-policy"

  policy = templatefile(
    "${path.module}/policies/${each.value.policy_name}.json.tftpl",
    {
      account_id  = data.aws_caller_identity.current.account_id
      region      = data.aws_region.current.region
      environment = each.value.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "nasc_terraform_service" {
  for_each = local.attachment_combinations

  role = aws_iam_role.nasc_terraform[
    each.value.environment
  ].name

  policy_arn = aws_iam_policy.nasc_terraform_service[
    each.key
  ].arn
}

output "github_actions_role_arn" {
  value = {
    for environment, role in aws_iam_role.nasc_terraform :
    environment => role.arn
  }
}