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
    "lambda",
    "sqs"
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
    "lambda"

    # Future integrations requiring security review.
    # "ec2-integrations",
    # "ecr-sharing",
    # "cloudwatch-composite",

  ])
}

resource "aws_iam_role" "nasc_terraform" {
  name = "nasc_terraform"
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
            "token.actions.githubusercontent.com:sub" = "repo:ghbamorim@79848031/NASC@1455266988:environment:dev"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "nasc_terraform_service" {
  for_each = local.policy_names

  name = "nasc-terraform-${each.key}-policy"

  policy = templatefile(
    "${path.module}/policies/${each.key}.json",
    {
      account_id = data.aws_caller_identity.current.account_id
      region     = data.aws_region.current.region
    }
  )
}

resource "aws_iam_role_policy_attachment" "nasc_terraform_service" {
  for_each = local.attached_policy_names

  role       = aws_iam_role.nasc_terraform.name
  policy_arn = aws_iam_policy.nasc_terraform_service[each.key].arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.nasc_terraform.arn
}