#!/usr/bin/env bash
set -euo pipefail

ZAPRET_DIR="/opt/zapret"
SERVICE="$ZAPRET_DIR/init.d/macos/zapret"

if [[ ! -f "$SERVICE" ]]; then
  echo "Zapret service not found at: $SERVICE"
  echo "Please run install.sh first."
  exit 1
fi

echo "Restarting Zapret..."
sudo "$SERVICE" restart

echo "Enabling macOS PF..."
sudo pfctl -e 2>/dev/null || true

echo "Done."
