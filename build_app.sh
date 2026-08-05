#!/bin/bash

# Exit on any error
set -e

echo "=== Building LidFlow Swift executable ==="
swift build -c release

echo "=== Packaging LidFlow.app bundle ==="
# Clean old app bundle
rm -rf LidFlow.app

# Create directory structure
mkdir -p LidFlow.app/Contents/MacOS

# Copy binary
cp .build/release/LidFlow LidFlow.app/Contents/MacOS/LidFlow

# Create Resources directory and package assets
mkdir -p LidFlow.app/Contents/Resources
cp creak_loop.wav LidFlow.app/Contents/Resources/creak_loop.wav
cp logo.png LidFlow.app/Contents/Resources/logo.png

# Create a temporary AppIcon.iconset folder
mkdir -p AppIcon.iconset

# Resize logo.png to standard macOS sizes using sips
sips -z 16 16 logo.png --out AppIcon.iconset/icon_16x16.png > /dev/null 2>&1
sips -z 32 32 logo.png --out AppIcon.iconset/icon_16x16@2x.png > /dev/null 2>&1
sips -z 32 32 logo.png --out AppIcon.iconset/icon_32x32.png > /dev/null 2>&1
sips -z 64 64 logo.png --out AppIcon.iconset/icon_32x32@2x.png > /dev/null 2>&1
sips -z 128 128 logo.png --out AppIcon.iconset/icon_128x128.png > /dev/null 2>&1
sips -z 256 256 logo.png --out AppIcon.iconset/icon_128x128@2x.png > /dev/null 2>&1
sips -z 256 256 logo.png --out AppIcon.iconset/icon_256x256.png > /dev/null 2>&1
sips -z 512 512 logo.png --out AppIcon.iconset/icon_256x256@2x.png > /dev/null 2>&1
sips -z 512 512 logo.png --out AppIcon.iconset/icon_512x512.png > /dev/null 2>&1
sips -z 1024 1024 logo.png --out AppIcon.iconset/icon_512x512@2x.png > /dev/null 2>&1

# Compile the iconset into AppIcon.icns inside Resources
iconutil -c icns AppIcon.iconset --o LidFlow.app/Contents/Resources/AppIcon.icns

# Clean up temporary iconset folder
rm -rf AppIcon.iconset

# Create Info.plist
cat <<EOF > LidFlow.app/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>LidFlow</string>
    <key>CFBundleIdentifier</key>
    <string>com.umair.LidFlow</string>
    <key>CFBundleName</key>
    <string>LidFlow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
</dict>
</plist>
EOF

echo "=== Build and Package Successful ==="
echo "You can now run LidFlow.app!"
