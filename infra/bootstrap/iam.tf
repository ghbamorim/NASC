resource "aws_iam_user" "nasc_terraform" {
  name = "nasc-terraform"
  path = "/"

  tags = {
    Project   = "NASC"
    ManagedBy = "Terraform"
  }
}

resource "aws_iam_policy" "nasc_backend" {
  name   = "nasc-terraform-backend-policy"
  policy = file("${path.module}/policies/backend.json")
}

resource "aws_iam_user_policy_attachment" "nasc_backend" {
  user       = aws_iam_user.nasc_terraform.name
  policy_arn = aws_iam_policy.nasc_backend.arn
}

data "aws_iam_openid_connect_provider" "github" {
  arn = "arn:aws:iam::242627333067:oidc-provider/token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:ghbamorim@79848031/NASC@1455266988:ref:refs/heads/main",
        "repo:ghbamorim@79848031/NASC@1455266988:pull_request"
      ]

    }
  }
}

resource "aws_iam_role" "nasc_dev_deploy" {
  name               = "nasc-dev-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json

  tags = {
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "nasc_dev_backend" {
  role       = aws_iam_role.nasc_dev_deploy.name
  policy_arn = aws_iam_policy.nasc_backend.arn
}


data "aws_iam_policy_document" "github_plan_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        data.aws_iam_openid_connect_provider.github.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:ghbamorim@79848031/NASC@1455266988:pull_request"
      ]
    }
  }
}

resource "aws_iam_role" "nasc_dev_plan" {
  name               = "nasc-dev-plan"
  assume_role_policy = data.aws_iam_policy_document.github_plan_assume.json

  tags = {
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_policy" "nasc_plan_backend" {
  name   = "nasc-dev-plan-backend-policy"
  policy = file("${path.module}/policies/plan-backend.json")
}

resource "aws_iam_role_policy_attachment" "nasc_plan_backend" {
  role       = aws_iam_role.nasc_dev_plan.name
  policy_arn = aws_iam_policy.nasc_plan_backend.arn
}



resource "aws_iam_role_policy" "nasc_dev_cloudwatch" {
  name = "nasc-dev-cloudwatch"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "DescribeLogGroups"
        Effect = "Allow"

        Action = [
          "logs:DescribeLogGroups"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      },
      {
        Sid    = "ManageNascLogGroup"
        Effect = "Allow"

        Action = [
          "logs:CreateLogGroup",
          "logs:ListTagsForResource",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource",
          "logs:DeleteLogGroup"
        ]

        Resource = [
          "arn:aws:logs:us-east-2:242627333067:log-group:/nasc/dev/app",
          "arn:aws:logs:us-east-2:242627333067:log-group:/nasc/dev/app:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_plan_cloudwatch" {
  name = "nasc-dev-plan-cloudwatch"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadCloudWatchLogGroups"
        Effect = "Allow"

        Action = [
          "logs:DescribeLogGroups"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      },
      {
        Sid    = "ReadNascLogGroup"
        Effect = "Allow"

        Action = [
          "logs:ListTagsForResource"
        ]

        Resource = "arn:aws:logs:us-east-2:242627333067:log-group:/nasc/dev/app"
      }
    ]
  })
}
