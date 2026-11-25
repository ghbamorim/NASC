#!/usr/bin/env bash

set -euo pipefail

echo "Waiting for instance initialization..."

cloud-init status --wait

docker --version
docker compose version
systemctl is-active --quiet docker

cd /opt/nasc
umask 077

export AWS_DEFAULT_REGION="${1:?AWS region is required}"
export BACKEND_IMAGE="${2:?Backend image is required}"
export DB_HOST="${3:?Database host is required}"
export GEMINI_MODEL="${4:?Gemini model is required}"
export GEMINI_FALLBACK_MODELS="${5:?Gemini fallback models are required}"

REGISTRY="${BACKEND_IMAGE%%/*}"

echo "Loading application secrets..."

SECRETS=$(aws secretsmanager get-secret-value \
    --secret-id nasc/dev/app \
    --query SecretString \
    --output text)

DB_PASSWORD=$(jq -er '.DB_PASSWORD | select(length > 0)' <<< "$SECRETS")
JWT_SECRET_KEY=$(jq -er '.JWT_SECRET_KEY | select(length > 0)' <<< "$SECRETS")
TELEGRAM_BOT_TOKEN=$(jq -er '.TELEGRAM_BOT_TOKEN | select(length > 0)' <<< "$SECRETS")
GEMINI_API_KEY=$(jq -er '.GEMINI_API_KEY | select(length > 0)' <<< "$SECRETS")
CHANNEL_API_KEY=$(jq -er '.CHANNEL_API_KEY | select(length > 0)' <<< "$SECRETS")

export DB_PASSWORD
export JWT_SECRET_KEY
export TELEGRAM_BOT_TOKEN
export GEMINI_API_KEY
export CHANNEL_API_KEY

DATABASE_URL=$(python3 - <<'PY'
import os
from urllib.parse import quote

password = quote(os.environ["DB_PASSWORD"], safe="")
host = os.environ["DB_HOST"]

print(f"postgresql+asyncpg://nasc_admin:{password}@{host}:5432/nasc")
PY
)

export DATABASE_URL

TELEGRAM_BOT_USERNAME=$(jq -er '.TELEGRAM_BOT_USERNAME | select(length > 0)' <<< "$SECRETS")
CHANNEL_LINK_TOKEN_EXPIRE_MINUTES=$(jq -er '.CHANNEL_LINK_TOKEN_EXPIRE_MINUTES' <<< "$SECRETS")

export TELEGRAM_BOT_USERNAME
export CHANNEL_LINK_TOKEN_EXPIRE_MINUTES

unset SECRETS DB_PASSWORD

echo "Authenticating with ECR..."

aws ecr get-login-password \
    | docker login \
        --username AWS \
        --password-stdin "$REGISTRY"

echo "Pulling backend image..."

docker compose pull

echo "Running database migrations..."

docker compose run --rm backend alembic upgrade head

echo "Starting backend..."

docker compose up -d \
    --remove-orphans \
    --wait \
    --wait-timeout 120

echo "Checking application health..."

curl -fsS http://localhost:8000/health

echo "Removing unused images..."

docker image prune -af

docker logout "$REGISTRY"

echo "Deployment completed successfully."