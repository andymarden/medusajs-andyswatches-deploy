#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/srv/medusajs/andyswatches"
STOREFRONT_DIR="$APP_DIR/apps/storefront"
SERVICE="medusajs-storefront"
ENV_FILE="/etc/medusajs/storefront.env"

sudo systemctl daemon-reload
systemctl cat "$SERVICE" >/dev/null

systemctl is-active --quiet "$SERVICE" && sudo systemctl stop "$SERVICE" || true

cd "$APP_DIR"
git pull --ff-only

corepack enable
corepack prepare pnpm@10.11.1 --activate
pnpm install --frozen-lockfile --force

echo "=== Preparing storefront environment ==="
cp "$ENV_FILE" "$STOREFRONT_DIR/.env"
cp "$ENV_FILE" "$STOREFRONT_DIR/.env.production"
chmod 600 "$STOREFRONT_DIR/.env" "$STOREFRONT_DIR/.env.production"

cd "$STOREFRONT_DIR"
pnpm build

sudo systemctl start "$SERVICE"
systemctl is-active --quiet "$SERVICE"

curl -f http://127.0.0.1:8000
echo
echo "Storefront deployment complete."
