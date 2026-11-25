#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

rm -rf build function.zip

uv export --frozen --no-dev --no-hashes --no-emit-project -o requirements.txt

uv pip install --python 3.14 --target build -r requirements.txt

cp handler.py build/

cd build
uv run --no-project --python 3.14 python -m zipfile -c ../function.zip *