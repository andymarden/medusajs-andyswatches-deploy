#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/srv/medusajs/andyswatches"
STOREFRONT_DIR="$APP_DIR/apps/storefront"
SERVICE="medusajs-storefront"

systemctl daemon-reload
systemctl cat "$SERVICE" >/dev/null

systemctl is-active --quiet "$SERVICE" && systemctl stop "$SERVICE" || true

cd "$APP_DIR"
sudo -u medusajs git pull --ff-only

sudo -u medusajs corepack enable
sudo -u medusajs corepack prepare pnpm@10.11.1 --activate
sudo -u medusajs pnpm install --frozen-lockfile --force

cd "$STOREFRONT_DIR"
sudo -u medusajs pnpm build

chown -R medusajs:medusajs "$APP_DIR"

systemctl start "$SERVICE"
systemctl is-active --quiet "$SERVICE"

curl -f http://127.0.0.1:8000
echo
echo "Storefront deployment complete."
