#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/Zapret Menu.app"
DMG_ROOT="$BUILD_DIR/dmg-root"
DMG_PATH="$BUILD_DIR/Zapret-Menu-1.4.0.dmg"

"$ROOT_DIR/scripts/build-app.sh"

rm -rf "$DMG_ROOT" "$DMG_PATH"
mkdir -p "$DMG_ROOT"
cp -R "$APP_DIR" "$DMG_ROOT/"
ln -s /Applications "$DMG_ROOT/Applications"

/usr/bin/hdiutil create \
    -volname "Zapret Menu" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_ROOT"

CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
if [[ "$CODESIGN_IDENTITY" != "-" ]]; then
    /usr/bin/codesign --force --timestamp \
        --sign "$CODESIGN_IDENTITY" "$DMG_PATH"
fi

echo "$DMG_PATH"
