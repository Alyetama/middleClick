#!/bin/bash
set -euo pipefail

APP="MiddleClick"
BUNDLE_ID="com.fcatus.middleclick"
VERSION="1.0.0"

echo "==> Building ($APP) release binary…"
swift build -c release

BIN=".build/release/$APP"
APPDIR="$APP.app"

echo "==> Assembling $APPDIR…"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/Contents/MacOS" "$APPDIR/Contents/Resources"
cp "$BIN" "$APPDIR/Contents/MacOS/$APP"

if [ -f AppIcon.icns ]; then
    cp AppIcon.icns "$APPDIR/Contents/Resources/AppIcon.icns"
fi

cat > "$APPDIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>$APP</string>
    <key>CFBundleDisplayName</key>     <string>$APP</string>
    <key>CFBundleExecutable</key>      <string>$APP</string>
    <key>CFBundleIdentifier</key>      <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>         <string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>  <string>13.0</string>
    <key>LSUIElement</key>             <true/>
    <key>NSHumanReadableCopyright</key><string>MIT</string>
</dict>
</plist>
EOF

echo "==> Ad-hoc signing…"
codesign --force --deep --sign - "$APPDIR"

echo "==> Done: $APPDIR"
echo "    Move it to /Applications, then grant Accessibility access on first run."
