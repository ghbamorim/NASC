data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "main" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  iam_instance_profile = "nasc-dev-ec2-profile"

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  lifecycle {
    ignore_changes = [ami]
  }

  credit_specification {
    cpu_credits = "standard"
  }

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    set -e

    dnf install -y docker
    systemctl enable --now docker
    systemctl enable --now amazon-ssm-agent
    usermod -aG docker ec2-user
  EOF

  tags = {
    Name        = "nasc-dev-ec2"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  volume_tags = {
    Name        = "nasc-dev-ec2-volume"
    Project     = "NASC"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_route_table_association.public,
    aws_db_instance.main,
    aws_secretsmanager_secret.app
  ]
}

output "ec2_instance_id" {
  value = aws_instance.main.id
}