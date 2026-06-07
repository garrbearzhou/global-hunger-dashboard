#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "" ]]; then
  echo "Usage: ./deploy/deploy.sh yourdomain.com"
  exit 1
fi

DOMAIN="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CADDYFILE="$ROOT/deploy/Caddyfile"

sed "s/example.com/${DOMAIN}/g" "$ROOT/deploy/Caddyfile" > "$CADDYFILE"
cd "$ROOT"
docker compose up -d --build

echo "Deployed. Point DNS for ${DOMAIN} to this server's public IP."
