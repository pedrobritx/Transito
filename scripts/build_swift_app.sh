#!/bin/bash

# Transito SwiftUI App Builder
# This script builds the native SwiftUI macOS app

set -e

APP_NAME="Transito"
VERSION=$(cat VERSION)

echo "Building ${APP_NAME} SwiftUI app ${VERSION}..."

# Check if Xcode is available
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "Error: Xcode command line tools not found. Install with: xcode-select --install"
    exit 1
fi

# Build Swift app
echo "Building SwiftUI app..."
cd packages/macos
xcodebuild -project Transito.xcodeproj \
           -scheme Transito \
           -configuration Release \
           -derivedDataPath build \
           -archivePath Transito.xcarchive \
           archive

# Create app bundle
echo "Creating app bundle..."
xcodebuild -exportArchive \
           -archivePath Transito.xcarchive \
           -exportPath ../.. \
           -exportOptionsPlist ExportOptions.plist

cd ../..

echo "✅ ${APP_NAME} SwiftUI app built successfully!"
echo "📱 App location: $(pwd)/Transito.app"
echo ""
echo "To test the app:"
echo "  open Transito.app"
echo ""
echo "To create DMG:"
echo "  ./scripts/create_dmg.sh"
