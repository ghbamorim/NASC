#!/usr/bin/env bash
set -euo pipefail

DEPLOY_DIR="/opt/nasc/deploy"
cd "$DEPLOY_DIR"

: "${ECR_IMAGE:?ECR_IMAGE is required}"
: "${AWS_REGION:?AWS_REGION is required}"
: "${DB_HOST:?DB_HOST is required}"
: "${DB_SECRET_ARN:?DB_SECRET_ARN is required}"
: "${APP_SECRET_ID:?APP_SECRET_ID is required}"
: "${BOT_TOKEN_SECRET_ARN:?BOT_TOKEN_SECRET_ARN is required}"

umask 077

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$DB_SECRET_ARN" \
  --query SecretString \
  --output text > "$TEMP_DIR/database.json"

aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$APP_SECRET_ID" \
  --query SecretString \
  --output text > "$TEMP_DIR/app.json"

aws secretsmanager get-secret-value \
  --region "$AWS_REGION" \
  --secret-id "$BOT_TOKEN_SECRET_ARN" \
  --query SecretString \
  --output text > "$TEMP_DIR/telegram.txt"

DB_HOST="$DB_HOST" TEMP_DIR="$TEMP_DIR" python3 - <<'PY'
import json
import os
from pathlib import Path
from urllib.parse import quote

temp = Path(os.environ["TEMP_DIR"])
db = json.loads((temp / "database.json").read_text())
app = json.loads((temp / "app.json").read_text())
token = (temp / "telegram.txt").read_text().strip()

database_url = (
    "postgresql+asyncpg://"
    f"{quote(db['username'], safe='')}:"
    f"{quote(db['password'], safe='')}@"
    f"{os.environ['DB_HOST']}/nasc"
)

values = {
    "DATABASE_URL": database_url,
    "JWT_SECRET_KEY": app["JWT_SECRET_KEY"],
    "GEMINI_API_KEY": app["GEMINI_API_KEY"],
    "GEMINI_MODEL": app["GEMINI_MODEL"],
    "TELEGRAM_BOT_TOKEN": token,
}

for key, value in values.items():
    if "\n" in value or "\r" in value:
        raise ValueError(f"Invalid newline in {key}")

Path(".env.tmp").write_text(
    "".join(f"{key}={value}\n" for key, value in values.items())
)
os.chmod(".env.tmp", 0o600)
os.replace(".env.tmp", ".env")
PY

ECR_REGISTRY="${ECR_IMAGE%%/*}"

aws ecr get-login-password --region "$AWS_REGION" |
  docker login \
    --username AWS \
    --password-stdin "$ECR_REGISTRY"

docker compose pull
docker compose up -d --remove-orphans

echo "NASC deployment completed."
