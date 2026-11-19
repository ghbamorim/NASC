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
        "repo:ghbamorim@79848031/NASC@1455266988:ref:refs/heads/main"
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