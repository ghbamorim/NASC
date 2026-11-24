resource "aws_iam_role" "dev_ec2" {
  name = "nasc-dev-ec2-role"
  path = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "nasc-dev-ec2-role"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "dev_ec2_ssm" {
  role       = aws_iam_role.dev_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "dev_ec2_secrets" {
  name        = "nasc-dev-ec2-secrets-policy"
  description = "Allows the NASC dev EC2 to read the application secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadNASCAppSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:secret:nasc/dev/app-??????"
      }
    ]
  })

  tags = {
    Environment = "dev"
  }
}

resource "aws_iam_role_policy_attachment" "dev_ec2_secrets" {
  role       = aws_iam_role.dev_ec2.name
  policy_arn = aws_iam_policy.dev_ec2_secrets.arn
}

resource "aws_iam_instance_profile" "dev_ec2" {
  name = "nasc-dev-ec2-profile"
  path = "/"
  role = aws_iam_role.dev_ec2.name

  tags = {
    Name        = "nasc-dev-ec2-profile"
    Environment = "dev"
  }
}

resource "aws_iam_role_policy" "ec2_ecr" {
  name = "nasc-dev-ec2-ecr-policy"
  role = aws_iam_role.dev_ec2.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:repository/nasc/dev/backend"
      }
    ]
  })
}