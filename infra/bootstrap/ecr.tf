resource "aws_ecr_repository" "backend" {
  name                 = "nasc/backend"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name = "nasc-backend-ecr"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.backend.repository_url
}