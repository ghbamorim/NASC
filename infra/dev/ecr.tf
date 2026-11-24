resource "aws_ecr_repository" "backend" {
  name                 = "nasc/dev/backend"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "nasc-dev-backend-ecr"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "backend" {
  repository = aws_ecr_repository.backend.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 5 images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}