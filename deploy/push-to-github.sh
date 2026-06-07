#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" == "" ]]; then
  echo "Usage: ./deploy/push-to-github.sh <github-repo-url>"
  echo "Example: ./deploy/push-to-github.sh https://github.com/garrbearzhou/global-hunger-research.git"
  exit 1
fi

REPO_URL="$1"

if [[ ! -d .git ]]; then
  git init
  git branch -M main
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  git add .
  git commit -m "$(cat <<'EOF'
Prepare Global Hunger Research app for Railway deployment.

Add Docker production setup and deployment config so the Shiny app can run on Railway with a custom domain.
EOF
)"
fi

if git remote | grep -q '^origin$'; then
  git remote set-url origin "$REPO_URL"
else
  git remote add origin "$REPO_URL"
fi

git push -u origin main
echo "Pushed to $REPO_URL"
