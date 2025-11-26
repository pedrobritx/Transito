#!/bin/bash

# Transito DMG Creator
# Creates a DMG file for distribution using hdiutil

set -e

APP_NAME="Transito"
VERSION=$(cat VERSION)
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOL_NAME="${APP_NAME}"

# Ensure we have the app bundle
if [ ! -d "${APP_NAME}.app" ]; then
    echo "Error: ${APP_NAME}.app not found. Please run build_swift_app.sh first."
    exit 1
fi

echo "Creating DMG for ${APP_NAME} ${VERSION}..."

# Create a temporary directory for the DMG contents
STAGING_DIR=$(mktemp -d)
cp -R "${APP_NAME}.app" "${STAGING_DIR}/"

# Create a symlink to Applications folder
ln -s /Applications "${STAGING_DIR}/Applications"

# Create the DMG
echo "Generating DMG..."
rm -f "${DMG_NAME}"
hdiutil create -volname "${VOL_NAME}" \
               -srcfolder "${STAGING_DIR}" \
               -ov -format UDZO \
               "${DMG_NAME}"

# Cleanup
rm -rf "${STAGING_DIR}"

echo "✅ DMG created: ${DMG_NAME}"
