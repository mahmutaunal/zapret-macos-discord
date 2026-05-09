#!/usr/bin/env bash
set -euo pipefail

ZAPRET_DIR="/opt/zapret"
UNINSTALLER="$ZAPRET_DIR/uninstall_easy.sh"

echo "========================================"
echo " Zapret macOS Discord Uninstaller"
echo "========================================"

if [[ ! -f "$UNINSTALLER" ]]; then
  echo "Zapret uninstaller not found at: $UNINSTALLER"
  echo "Nothing to uninstall."
  exit 0
fi

cd "$ZAPRET_DIR"

echo ""
echo "Running official Zapret uninstaller..."

sudo ./uninstall_easy.sh

echo ""
echo "Disabling macOS PF..."
sudo pfctl -d 2>/dev/null || true

echo ""
echo "Done."
