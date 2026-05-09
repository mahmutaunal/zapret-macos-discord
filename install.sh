#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="/tmp/zapret-macos"
ZAPRET_DIR="/opt/zapret"

echo "========================================"
echo " Zapret macOS Discord Installer"
echo "========================================"

ARCH="$(uname -m)"

if [[ "$ARCH" != "arm64" ]]; then
  echo ""
  echo "This installer currently supports Apple Silicon only."
  echo "Detected architecture: $ARCH"
  exit 1
fi

echo ""
echo "Architecture: $ARCH"

if ! command -v git >/dev/null 2>&1; then
  echo ""
  echo "Git is required but not installed."
  exit 1
fi

if [[ -d "$ZAPRET_DIR" ]]; then
  echo ""
  echo "Existing Zapret installation detected at:"
  echo "$ZAPRET_DIR"
  echo ""
  echo "Please uninstall existing Zapret first:"
  echo "./uninstall.sh"
  exit 1
fi

echo ""
echo "Cloning official Zapret repository..."

rm -rf "$TMP_DIR"

git clone --depth 1 https://github.com/bol-van/zapret.git "$TMP_DIR"

cd "$TMP_DIR"

echo ""
echo "Starting official installer..."

chmod +x install_easy.sh

sudo ./install_easy.sh <<EOF
Y
N
3
N
Y
N
1

N
EOF

echo ""
echo "Applying custom Discord config..."

sudo cp "$REPO_DIR/config/zapret-config.template" "$ZAPRET_DIR/config"

echo ""
echo "Installing Discord host list..."

sudo cp "$REPO_DIR/config/discord-hosts.txt" "$ZAPRET_DIR/ipset/zapret-hosts-user.txt"

echo ""
echo "Restarting Zapret..."

sudo "$ZAPRET_DIR/init.d/macos/zapret" restart

echo ""
echo "Enabling PF..."

sudo pfctl -e 2>/dev/null || true

echo ""
echo "========================================"
echo " Installation completed successfully."
echo "========================================"

echo ""
echo "If Discord gets stuck in update loop:"
echo "1. Let Discord reach the final update step"
echo "2. Stop Zapret temporarily"
echo "3. Let Discord finish update"
echo "4. Restart Zapret"
echo ""
