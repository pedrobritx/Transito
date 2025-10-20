#!/bin/bash

# Transito macOS App Builder
# This script creates a proper macOS app bundle using the new structure

set -e

APP_NAME="Transito"
APP_BUNDLE="${APP_NAME}.app"
VERSION=$(cat VERSION)

echo "Building ${APP_NAME} ${VERSION}..."

# Clean up any existing app bundle
if [ -d "$APP_BUNDLE" ]; then
    echo "Removing existing app bundle..."
    rm -rf "$APP_BUNDLE"
fi

# Create app bundle structure
echo "Creating app bundle structure..."
mkdir -p "$APP_BUNDLE/Contents/"{MacOS,Resources}

# Copy core CLI tool to Resources
echo "Copying core CLI tool..."
cp packages/core/transito "$APP_BUNDLE/Contents/Resources/"

# Create Info.plist
echo "Creating Info.plist..."
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Transito</string>
    <key>CFBundleIdentifier</key>
    <string>com.transito.hls-downloader</string>
    <key>CFBundleName</key>
    <string>Transito</string>
    <key>CFBundleDisplayName</key>
    <string>Transito</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>M3U8 Playlist</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>m3u8</string>
            </array>
            <key>CFBundleTypeMIMETypes</key>
            <array>
                <string>application/vnd.apple.mpegurl</string>
                <string>application/x-mpegURL</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create app launcher script
echo "Creating app launcher..."
cat > "$APP_BUNDLE/Contents/MacOS/Transito" << 'EOF'
#!/bin/bash

# Transito macOS App Launcher
# This script ensures Python and dependencies are available before launching the GUI

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$SCRIPT_DIR")"
RESOURCES_DIR="$APP_DIR/Resources"

# Try to find Python 3
PYTHON3=""
for python_cmd in python3 /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
    if command -v "$python_cmd" >/dev/null 2>&1; then
        PYTHON3="$python_cmd"
        break
    fi
done

if [ -z "$PYTHON3" ]; then
    osascript -e 'display dialog "Python 3 not found. Please install Python 3 from python.org or via Homebrew." buttons {"OK"} default button "OK" with title "Transito - Missing Python"'
    exit 1
fi

# Check if ffmpeg is available
if ! command -v ffmpeg >/dev/null 2>&1; then
    osascript -e 'display dialog "ffmpeg not found. Please install ffmpeg via Homebrew:\n\nbrew install ffmpeg" buttons {"OK"} default button "OK" with title "Transito - Missing ffmpeg"'
    exit 1
fi

# Check if ffprobe is available
if ! command -v ffprobe >/dev/null 2>&1; then
    osascript -e 'display dialog "ffprobe not found. Please install ffmpeg via Homebrew:\n\nbrew install ffmpeg" buttons {"OK"} default button "OK" with title "Transito - Missing ffprobe"'
    exit 1
fi

# Launch the GUI
cd "$RESOURCES_DIR"
exec "$PYTHON3" transito_gui.py
EOF

# Make launcher executable
chmod +x "$APP_BUNDLE/Contents/MacOS/Transito"

# Copy Python GUI (for backward compatibility)
echo "Copying Python GUI..."
cp transito_gui.py "$APP_BUNDLE/Contents/Resources/"

# Create app icon
echo "Creating app icon..."
python3 -c "
from PIL import Image, ImageDraw
import os

# Create a simple icon
size = 512
img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Draw a download arrow icon
center = size // 2
arrow_size = size // 3

# Background circle
draw.ellipse([size//8, size//8, 7*size//8, 7*size//8], fill=(52, 101, 164, 255))

# Arrow shape
points = [
    (center - arrow_size//2, center - arrow_size//2),
    (center + arrow_size//2, center),
    (center - arrow_size//2, center + arrow_size//2),
    (center - arrow_size//4, center),
    (center - arrow_size//2, center - arrow_size//2)
]
draw.polygon(points, fill=(255, 255, 255, 255))

# Save as PNG
img.save('${APP_BUNDLE}/Contents/Resources/icon.png')
print('Icon created successfully')
"

# Create ICNS file
echo "Creating ICNS file..."
mkdir -p icon.iconset
sips -z 16 16 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_16x16.png >/dev/null 2>&1
sips -z 32 32 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_16x16@2x.png >/dev/null 2>&1
sips -z 32 32 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_32x32.png >/dev/null 2>&1
sips -z 64 64 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_32x32@2x.png >/dev/null 2>&1
sips -z 128 128 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_128x128.png >/dev/null 2>&1
sips -z 256 256 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_128x128@2x.png >/dev/null 2>&1
sips -z 256 256 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_256x256.png >/dev/null 2>&1
sips -z 512 512 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_256x256@2x.png >/dev/null 2>&1
sips -z 512 512 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_512x512.png >/dev/null 2>&1
sips -z 1024 1024 "${APP_BUNDLE}/Contents/Resources/icon.png" --out icon.iconset/icon_512x512@2x.png >/dev/null 2>&1

iconutil -c icns icon.iconset -o "${APP_BUNDLE}/Contents/Resources/icon.icns" >/dev/null 2>&1
rm -rf icon.iconset

echo "✅ ${APP_NAME} app bundle created successfully!"
echo "📱 App location: $(pwd)/${APP_BUNDLE}"
echo ""
echo "To test the app:"
echo "  open ${APP_BUNDLE}"
echo ""
echo "To distribute:"
echo "  zip -r ${APP_NAME}-${VERSION}.zip ${APP_BUNDLE}"
