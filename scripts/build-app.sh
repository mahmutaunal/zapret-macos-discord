#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
APP_DIR="$BUILD_DIR/Zapret Menu.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
ICON_SOURCE="$BUILD_DIR/AppIcon-1024.png"

cd "$ROOT_DIR"
mkdir -p "$BUILD_DIR/module-cache"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/module-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$BUILD_DIR/module-cache"
swift build -c release --arch arm64 --disable-sandbox -debug-info-format none

rm -rf "$APP_DIR" "$ICONSET_DIR" "$ICON_SOURCE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$ICONSET_DIR"

cp ".build/release/ZapretMenu" "$MACOS_DIR/ZapretMenu"

cat > "$CONTENTS_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Zapret Menu</string>
    <key>CFBundleExecutable</key>
    <string>ZapretMenu</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.mahmutaunal.zapret-menu</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Zapret Menu</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.4.0</string>
    <key>CFBundleVersion</key>
    <string>5</string>
    <key>CFBundleLocalizations</key>
    <array>
        <string>en</string>
        <string>tr</string>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>Zapret servisini yönetici onayıyla başlatmak ve durdurmak için kullanılır.</string>
</dict>
</plist>
PLIST

/usr/bin/xcrun swiftc -O -framework AppKit scripts/generate-icon.swift \
    -o "$BUILD_DIR/generate-icon"
"$BUILD_DIR/generate-icon" "$ICON_SOURCE"

for size in 16 32 128 256 512; do
    /usr/bin/sips -s format png -z "$size" "$size" "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    /usr/bin/sips -s format png -z "$double_size" "$double_size" "$ICON_SOURCE" \
        --out "$ICONSET_DIR/icon_${size}x${size}@2x.png" >/dev/null
done

/usr/bin/iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR" "$ICON_SOURCE" "$BUILD_DIR/generate-icon"

cp -R "$ROOT_DIR/Resources/Localization/." "$RESOURCES_DIR/"

# Ad-hoc signing makes local builds launch cleanly. Release builds should pass a
# Developer ID identity in CODESIGN_IDENTITY and be notarized before publishing.
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
    /usr/bin/codesign --force --options runtime --sign - "$APP_DIR"
else
    /usr/bin/codesign --force --options runtime --timestamp \
        --sign "$CODESIGN_IDENTITY" "$APP_DIR"
fi

echo "$APP_DIR"
