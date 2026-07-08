#!/usr/bin/env bash
set -euo pipefail

/usr/local/sbin/redeploy-medusa-backend.sh
/usr/local/sbin/redeploy-medusa-storefront.sh
