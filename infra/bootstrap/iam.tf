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
        Sid      = "DescribeLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
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
          "arn:aws:logs:us-east-2:242627333067:log-group:/nasc/dev/app:*",
          "arn:aws:logs:us-east-2:242627333067:log-group:/aws/lambda/nasc-dev-telegram-webhook",
          "arn:aws:logs:us-east-2:242627333067:log-group:/aws/lambda/nasc-dev-telegram-webhook:*"
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
        Sid      = "ReadCloudWatchLogGroups"
        Effect   = "Allow"
        Action   = ["logs:DescribeLogGroups"]
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
        Action = ["logs:ListTagsForResource"]
        Resource = [
          "arn:aws:logs:us-east-2:242627333067:log-group:/nasc/dev/app",
          "arn:aws:logs:us-east-2:242627333067:log-group:/aws/lambda/nasc-dev-telegram-webhook"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_sqs" {
  name = "nasc-dev-sqs"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageNascQueues"
        Effect = "Allow"
        Action = [
          "sqs:CreateQueue",
          "sqs:DeleteQueue",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:TagQueue",
          "sqs:UntagQueue"
        ]
        Resource = [
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-messages",
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-messages-dlq"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_plan_sqs" {
  name = "nasc-dev-plan-sqs"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadNascQueues"
        Effect = "Allow"
        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags"
        ]
        Resource = [
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-messages",
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-messages-dlq"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_secrets" {
  name = "nasc-dev-secrets"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:CreateSecret",
        "secretsmanager:DescribeSecret",
        "secretsmanager:DeleteSecret",
        "secretsmanager:UpdateSecret",
        "secretsmanager:TagResource",
        "secretsmanager:UntagResource",
        "secretsmanager:GetResourcePolicy"
      ]
      Resource = "arn:aws:secretsmanager:us-east-2:242627333067:secret:nasc/dev/telegram/*"
    }]
  })
}

resource "aws_iam_role_policy" "nasc_dev_plan_secrets" {
  name = "nasc-dev-plan-secrets"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetResourcePolicy"
      ]
      Resource = "arn:aws:secretsmanager:us-east-2:242627333067:secret:nasc/dev/telegram/*"
    }]
  })
}

resource "aws_iam_role_policy" "nasc_dev_lambda" {
  name = "nasc-dev-lambda"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageTelegramLambda"
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetFunctionRecursionConfig",
          "lambda:GetRuntimeManagementConfig",
          "lambda:ListVersionsByFunction",
          "lambda:ListTags",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:PutRuntimeManagementConfig",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:GetPolicy"
        ]
        Resource = "arn:aws:lambda:us-east-2:242627333067:function:nasc-dev-telegram-webhook"
      },
      {
        Sid      = "PassTelegramLambdaRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::242627333067:role/nasc-dev-telegram-webhook"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_lambda_iam" {
  name = "nasc-dev-lambda-iam"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageTelegramLambdaRole"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy"
        ]
        Resource = "arn:aws:iam::242627333067:role/nasc-dev-telegram-webhook"
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_plan_lambda" {
  name = "nasc-dev-plan-lambda"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadTelegramLambda"
        Effect = "Allow"
        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetFunctionRecursionConfig",
          "lambda:GetRuntimeManagementConfig",
          "lambda:ListVersionsByFunction",
          "lambda:ListTags",
          "lambda:GetPolicy"
        ]
        Resource = "arn:aws:lambda:us-east-2:242627333067:function:nasc-dev-telegram-webhook"
      },
      {
        Sid    = "ReadTelegramLambdaRole"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole"
        ]
        Resource = "arn:aws:iam::242627333067:role/nasc-dev-telegram-webhook"
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_api_gateway" {
  name = "nasc-dev-api-gateway"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageTelegramHttpApi"
        Effect = "Allow"
        Action = [
          "apigateway:POST",
          "apigateway:GET",
          "apigateway:PATCH",
          "apigateway:PUT",
          "apigateway:DELETE",
          "apigateway:TagResource",
          "apigateway:UntagResource"
        ]
        Resource = [
          "arn:aws:apigateway:us-east-2::/apis",
          "arn:aws:apigateway:us-east-2::/apis/*",
          "arn:aws:apigateway:us-east-2::/tags/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_plan_api_gateway" {
  name = "nasc-dev-plan-api-gateway"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadTelegramHttpApi"
        Effect = "Allow"
        Action = ["apigateway:GET"]
        Resource = [
          "arn:aws:apigateway:us-east-2::/apis",
          "arn:aws:apigateway:us-east-2::/apis/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_network" {
  name = "nasc-dev-network"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageDevNetwork"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:ReplaceRouteTableAssociation",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:Describe*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_plan_network" {
  name = "nasc-dev-plan-network"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadDevNetwork"
        Effect   = "Allow"
        Action   = ["ec2:Describe*"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_compute" {
  name = "nasc-dev-compute"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageEC2"
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:CreateVolume",
          "ec2:DeleteVolume",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:Describe*",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      },
      {
        Sid    = "ManageECR"
        Effect = "Allow"
        Action = [
          "ecr:CreateRepository",
          "ecr:DeleteRepository",
          "ecr:DescribeRepositories",
          "ecr:PutLifecyclePolicy",
          "ecr:GetLifecyclePolicy",
          "ecr:DeleteLifecyclePolicy",
          "ecr:TagResource",
          "ecr:UntagResource",
          "ecr:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageRDS"
        Effect = "Allow"
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
          "rds:CreateDBSubnetGroup",
          "rds:DeleteDBSubnetGroup",
          "rds:ModifyDBSubnetGroup",
          "rds:DescribeDBSubnetGroups",
          "rds:AddTagsToResource",
          "rds:RemoveTagsFromResource",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "ManageInstanceRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassEC2Role"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::242627333067:role/nasc-dev-ec2"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_plan_compute" {
  name = "nasc-dev-plan-compute"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ecr:DescribeRepositories",
          "ecr:GetLifecyclePolicy",
          "ecr:ListTagsForResource",
          "rds:DescribeDBInstances",
          "rds:DescribeDBSubnetGroups",
          "rds:ListTagsForResource",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetInstanceProfile",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "nasc_dev_delivery" {
  name = "nasc-dev-delivery"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuthorization"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "ECRPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:us-east-2:242627333067:repository/nasc-dev-backend"
      },
      {
        Sid    = "SSMDeploy"
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          "arn:aws:ssm:us-east-2::document/AWS-RunShellScript",
          "arn:aws:ec2:us-east-2:242627333067:instance/*"
        ]
      },
      {
        Sid    = "SSMCommandStatus"
        Effect = "Allow"
        Action = [
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# Telegram Consumer - GitHub Actions Deploy
# ============================================================

resource "aws_iam_role_policy" "nasc_dev_telegram_consumer_deploy" {
  name = "nasc-dev-telegram-consumer-deploy"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ManageConsumerLambda"
        Effect = "Allow"

        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetFunctionRecursionConfig",
          "lambda:GetRuntimeManagementConfig",
          "lambda:ListVersionsByFunction",
          "lambda:ListTags",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:PutRuntimeManagementConfig",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:GetPolicy"
        ]

        Resource = "arn:aws:lambda:us-east-2:242627333067:function:nasc-dev-telegram-consumer"
      },
      {
        Sid    = "ManageConsumerEventSourceMapping"
        Effect = "Allow"

        Action = [
          "lambda:CreateEventSourceMapping",
          "lambda:UpdateEventSourceMapping",
          "lambda:DeleteEventSourceMapping",
          "lambda:GetEventSourceMapping",
          "lambda:ListEventSourceMappings"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      },
      {
        Sid      = "PassConsumerLambdaRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::242627333067:role/nasc-dev-telegram-consumer"

        Condition = {
          StringEquals = {
            "iam:PassedToService" = "lambda.amazonaws.com"
          }
        }
      },
      {
        Sid    = "ManageConsumerIamRole"
        Effect = "Allow"

        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:DeleteRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy"
        ]

        Resource = "arn:aws:iam::242627333067:role/nasc-dev-telegram-consumer"
      },
      {
        Sid    = "ManageConsumerLogGroup"
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
          "arn:aws:logs:us-east-2:242627333067:log-group:/aws/lambda/nasc-dev-telegram-consumer",
          "arn:aws:logs:us-east-2:242627333067:log-group:/aws/lambda/nasc-dev-telegram-consumer:*"
        ]
      }
    ]
  })
}

# ============================================================
# Telegram Consumer - GitHub Actions Plan
# ============================================================

resource "aws_iam_role_policy" "nasc_dev_telegram_consumer_plan" {
  name = "nasc-dev-telegram-consumer-plan"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadConsumerLambda"
        Effect = "Allow"

        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetFunctionRecursionConfig",
          "lambda:GetRuntimeManagementConfig",
          "lambda:ListVersionsByFunction",
          "lambda:ListTags",
          "lambda:GetPolicy"
        ]

        Resource = "arn:aws:lambda:us-east-2:242627333067:function:nasc-dev-telegram-consumer"
      },
      {
        Sid    = "ReadConsumerEventSourceMapping"
        Effect = "Allow"

        Action = [
          "lambda:GetEventSourceMapping",
          "lambda:ListEventSourceMappings"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      },
      {
        Sid    = "ReadConsumerIamRole"
        Effect = "Allow"

        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole"
        ]

        Resource = "arn:aws:iam::242627333067:role/nasc-dev-telegram-consumer"
      },
      {
        Sid    = "ReadConsumerLogGroup"
        Effect = "Allow"

        Action = [
          "logs:ListTagsForResource"
        ]

        Resource = "arn:aws:logs:us-east-2:242627333067:log-group:/aws/lambda/nasc-dev-telegram-consumer"
      }
    ]
  })
}

# ============================================================
# Telegram Sender - Deploy (Managed Policy)
# ============================================================

resource "aws_iam_policy" "nasc_dev_telegram_sender_deploy" {
  name   = "nasc-dev-telegram-sender-deploy"
  policy = file("${path.module}/policies/telegram-sender-deploy.json")
}

resource "aws_iam_role_policy_attachment" "nasc_dev_telegram_sender_deploy" {
  role       = aws_iam_role.nasc_dev_deploy.name
  policy_arn = aws_iam_policy.nasc_dev_telegram_sender_deploy.arn
}

# ============================================================
# Telegram Sender - Plan
# ============================================================

resource "aws_iam_role_policy" "nasc_dev_telegram_sender_plan" {
  name = "nasc-dev-telegram-sender-plan"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadSenderLambda"
        Effect = "Allow"

        Action = [
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:GetFunctionConcurrency",
          "lambda:GetFunctionEventInvokeConfig",
          "lambda:GetFunctionRecursionConfig",
          "lambda:GetRuntimeManagementConfig",
          "lambda:ListVersionsByFunction",
          "lambda:ListTags",
          "lambda:GetPolicy"
        ]

        Resource = "arn:aws:lambda:us-east-2:242627333067:function:nasc-dev-telegram-sender"
      },
      {
        Sid    = "ReadSenderEventSourceMapping"
        Effect = "Allow"

        Action = [
          "lambda:GetEventSourceMapping",
          "lambda:ListEventSourceMappings"
        ]

        Resource = "*"

        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "us-east-2"
          }
        }
      },
      {
        Sid    = "ReadSenderIamRole"
        Effect = "Allow"

        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole"
        ]

        Resource = "arn:aws:iam::242627333067:role/nasc-dev-telegram-sender"
      },
      {
        Sid    = "ReadSenderLogGroup"
        Effect = "Allow"

        Action = [
          "logs:ListTagsForResource"
        ]

        Resource = "arn:aws:logs:us-east-2:242627333067:log-group:/aws/lambda/nasc-dev-telegram-sender"
      }
    ]
  })
}

# ============================================================
# Telegram Outgoing SQS - Deploy
# ============================================================

resource "aws_iam_role_policy" "nasc_dev_telegram_outgoing_sqs_deploy" {
  name = "nasc-dev-telegram-outgoing-sqs-deploy"
  role = aws_iam_role.nasc_dev_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ManageOutgoingQueues"
        Effect = "Allow"

        Action = [
          "sqs:CreateQueue",
          "sqs:DeleteQueue",
          "sqs:GetQueueAttributes",
          "sqs:SetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags",
          "sqs:TagQueue",
          "sqs:UntagQueue"
        ]

        Resource = [
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-telegram-outgoing",
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-telegram-outgoing-dlq"
        ]
      }
    ]
  })
}

# ============================================================
# Telegram Outgoing SQS - Plan
# ============================================================

resource "aws_iam_role_policy" "nasc_dev_telegram_outgoing_sqs_plan" {
  name = "nasc-dev-telegram-outgoing-sqs-plan"
  role = aws_iam_role.nasc_dev_plan.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ReadOutgoingQueues"
        Effect = "Allow"

        Action = [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ListQueueTags"
        ]

        Resource = [
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-telegram-outgoing",
          "arn:aws:sqs:us-east-2:242627333067:nasc-dev-telegram-outgoing-dlq"
        ]
      }
    ]
  })
}
