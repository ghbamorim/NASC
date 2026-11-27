data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "main" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.micro"

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ec2.name

  source_dest_check = false

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

  user_data_replace_on_change = true

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    dnf install -y docker iptables-nft

    systemctl enable --now docker

    cat > /usr/local/sbin/nasc-nat.sh <<'SCRIPT'
    #!/bin/bash
    set -euo pipefail

    sysctl -w net.ipv4.ip_forward=1

    iptables -t nat -C POSTROUTING \
      -s ${local.private_nat_cidr} -o ens5 -j MASQUERADE ||
    iptables -t nat -A POSTROUTING \
      -s ${local.private_nat_cidr} -o ens5 -j MASQUERADE

    iptables -C DOCKER-USER \
      -i ens5 -o ens5 -s ${local.private_nat_cidr} \
      -p tcp --dport 443 \
      -m conntrack --ctstate NEW,ESTABLISHED \
      -j ACCEPT ||
    iptables -I DOCKER-USER 1 \
      -i ens5 -o ens5 -s ${local.private_nat_cidr} \
      -p tcp --dport 443 \
      -m conntrack --ctstate NEW,ESTABLISHED \
      -j ACCEPT

    iptables -C DOCKER-USER \
      -i ens5 -o ens5 -d ${local.private_nat_cidr} \
      -m conntrack --ctstate ESTABLISHED,RELATED \
      -j ACCEPT ||
    iptables -I DOCKER-USER 1 \
      -i ens5 -o ens5 -d ${local.private_nat_cidr} \
      -m conntrack --ctstate ESTABLISHED,RELATED \
      -j ACCEPT
    SCRIPT

    chmod 700 /usr/local/sbin/nasc-nat.sh

    cat > /etc/systemd/system/nasc-nat.service <<'UNIT'
    [Unit]
    Description=NASC NAT configuration
    Wants=network-online.target
    Requires=docker.service
    After=network-online.target docker.service
    PartOf=docker.service

    [Service]
    Type=oneshot
    ExecStart=/usr/local/sbin/nasc-nat.sh
    RemainAfterExit=yes

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now nasc-nat.service

    systemctl enable --now amazon-ssm-agent

    usermod -aG docker ec2-user

    install -d /usr/local/lib/docker/cli-plugins

    curl -fsSL --retry 3 \
      https://github.com/docker/compose/releases/download/v5.6.0/docker-compose-linux-x86_64 \
      -o /usr/local/lib/docker/cli-plugins/docker-compose

    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    install -d -m 700 /opt/nasc

    docker --version
    docker compose version
    aws --version
    curl --version
    jq --version
    python3 --version
  EOF

  tags = {
    Name = "${local.name_prefix}-ec2"
  }

  volume_tags = {
    Name        = "${local.name_prefix}-ec2-volume"
    Project     = "NASC"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  depends_on = [
    aws_route_table_association.public,
    aws_db_instance.main,
    aws_secretsmanager_secret.app,
    aws_iam_role_policy_attachment.ec2_ssm,
    aws_iam_role_policy.ec2_secrets,
    aws_iam_role_policy.ec2_ecr
  ]
}

output "ec2_instance_id" {
  value = aws_instance.main.id
}