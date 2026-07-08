#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/srv/medusajs/andyswatches"
STOREFRONT_DIR="$APP_DIR/apps/storefront"
SERVICE="medusajs-storefront"

sudo systemctl daemon-reload
systemctl cat "$SERVICE" >/dev/null

systemctl is-active --quiet "$SERVICE" && sudo systemctl stop "$SERVICE" || true

cd "$APP_DIR"
git pull --ff-only

corepack enable
corepack prepare pnpm@10.11.1 --activate
pnpm install --frozen-lockfile --force

cd "$STOREFRONT_DIR"
pnpm build

sudo systemctl start "$SERVICE"
systemctl is-active --quiet "$SERVICE"

curl -f http://127.0.0.1:8000
echo
echo "Storefront deployment complete."
