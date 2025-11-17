#!/bin/bash

# Transito Release Script
# Creates distribution package for the native macOS app

set -e

APP_NAME="Transito"
VERSION=$(cat VERSION)
DIST_NAME="${APP_NAME}-${VERSION}"

echo "Creating distribution package for ${APP_NAME} ${VERSION}..."

# Build macOS app
echo "Building macOS app..."
./scripts/build_swift_app.sh

# Check if the app was built successfully
if [ ! -d "Transito.app" ]; then
    echo "Error: Transito.app not found after build"
    exit 1
fi

# Create DMG
echo "Creating DMG..."
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "Transito" \
        --volicon "Transito.app/Contents/Resources/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "Transito.app" 175 120 \
        --hide-extension "Transito.app" \
        --app-drop-link 425 120 \
        "${DIST_NAME}-macOS.dmg" \
        "Transito.app"
else
    echo "create-dmg not found. Creating ZIP instead..."
    zip -r "${DIST_NAME}-macOS.zip" "Transito.app"
fi

echo "✅ Distribution package created:"
if [ -f "${DIST_NAME}-macOS.dmg" ]; then
    echo "  - ${DIST_NAME}-macOS.dmg"
elif [ -f "${DIST_NAME}-macOS.zip" ]; then
    echo "  - ${DIST_NAME}-macOS.zip"
fi
echo ""
echo "To distribute:"
echo "  - Share the DMG/ZIP file via GitHub Releases"
echo "  - Users can drag Transito.app to Applications"
echo ""
echo "To install create-dmg for better packaging:"
echo "  brew install create-dmg"
