#!/bin/zsh
# Builds DesktopRotation.app into ./build (needs only Command Line Tools).
set -euo pipefail
cd "$(dirname "$0")"

APP=build/DesktopRotation.app
swift build -c release 2>&1 | grep -v "ld: warning" || true
BIN=$(swift build -c release --show-bin-path)/DesktopRotation

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/DesktopRotation"

ICONSET=build/AppIcon.iconset
swift Scripts/make_icon.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$ICONSET"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>DesktopRotation</string>
    <key>CFBundleDisplayName</key><string>DesktopRotation</string>
    <key>CFBundleIdentifier</key><string>com.liuqiong.DesktopRotation</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleExecutable</key><string>DesktopRotation</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
