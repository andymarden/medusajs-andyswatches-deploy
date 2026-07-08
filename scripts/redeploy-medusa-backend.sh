# !/usr/bin/env bash
# medusajs backend build and deploy
# Copy to /usr/local/sbin on the server
set -euo pipefail

APP_DIR="/srv/medusajs/andyswatches"
BACKEND_DIR="$APP_DIR/apps/backend"
BUILD_DIR="$BACKEND_DIR/.medusa/server"
ENV_FILE="/etc/medusajs/andyswatches.env"

SERVER_SERVICE="medusajs-server"
WORKER_SERVICE="medusajs-worker"

echo "=== Reloading systemd ==="
systemctl daemon-reload

echo "=== Checking services exist ==="
systemctl cat "$SERVER_SERVICE" >/dev/null
systemctl cat "$WORKER_SERVICE" >/dev/null

echo "=== Stopping Medusa services if running ==="
systemctl is-active --quiet "$WORKER_SERVICE" && systemctl stop "$WORKER_SERVICE" || true
systemctl is-active --quiet "$SERVER_SERVICE" && systemctl stop "$SERVER_SERVICE" || true

echo "=== Updating source ==="
cd "$APP_DIR"
sudo -u medusajs git pull --ff-only

echo "=== Installing workspace dependencies ==="
sudo -u medusajs corepack enable
sudo -u medusajs corepack prepare pnpm@10.11.1 --activate
sudo -u medusajs pnpm install --frozen-lockfile --force

echo "=== Building backend ==="
cd "$BACKEND_DIR"
sudo -u medusajs pnpm build

echo "=== Preparing production build ==="
cd "$BUILD_DIR"
cp "$APP_DIR/pnpm-lock.yaml" .
cp "$ENV_FILE" .env.production
chmod 600 .env.production

sudo -u medusajs pnpm install --prod --ignore-workspace ---no-frozen-lockfile --force

echo "=== Setting ownership ==="
chown -R medusajs:medusajs "$APP_DIR"

echo "=== Starting Medusa services ==="
systemctl start "$SERVER_SERVICE"
systemctl start "$WORKER_SERVICE"

echo "=== Checking service status ==="
systemctl is-active --quiet "$SERVER_SERVICE"
systemctl is-active --quiet "$WORKER_SERVICE"

echo "=== Waiting for Medusa health check ==="
for i in {1..30}; do
  if curl -fsS http://127.0.0.1:9000/health >/dev/null; then
    echo "Medusa is healthy."
    break
  fi

  echo "Waiting for Medusa... ($i/30)"
  sleep 2
done

curl -f http://127.0.0.1:9000/health
echo
echo "Deployment complete."

