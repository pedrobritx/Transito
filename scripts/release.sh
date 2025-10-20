#!/bin/bash

# Transito Release Script
# Creates distribution packages for both CLI and GUI

set -e

APP_NAME="Transito"
VERSION=$(cat VERSION)
DIST_NAME="${APP_NAME}-${VERSION}"

echo "Creating distribution packages for ${APP_NAME} ${VERSION}..."

# Clean up any existing distribution
if [ -d "$DIST_NAME" ]; then
    rm -rf "$DIST_NAME"
fi

mkdir -p "$DIST_NAME"

# Build CLI package
echo "Building CLI package..."
mkdir -p "$DIST_NAME/cli"
cp packages/core/transito "$DIST_NAME/cli/"
cp packages/core/setup.py "$DIST_NAME/cli/"
cp README.md "$DIST_NAME/cli/"

# Create CLI installer
cat > "$DIST_NAME/cli/install.sh" << 'EOF'
#!/bin/bash

echo "Installing Transito CLI..."
echo ""

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install dependencies
echo "Installing dependencies..."
brew install python ffmpeg

# Install CLI tool
echo "Installing Transito CLI..."
sudo cp transito /usr/local/bin/
sudo chmod +x /usr/local/bin/transito

echo ""
echo "✅ Installation complete!"
echo "Run 'transito --help' to get started"
EOF

chmod +x "$DIST_NAME/cli/install.sh"

# Build macOS app
echo "Building macOS app..."
./scripts/build_macos_app.sh
cp -R Transito.app "$DIST_NAME/"

# Create DMG
echo "Creating DMG..."
if command -v create-dmg >/dev/null 2>&1; then
    create-dmg \
        --volname "Transito" \
        --volicon "Transito.app/Contents/Resources/icon.icns" \
        --window-pos 200 120 \
        --window-size 600 300 \
        --icon-size 100 \
        --icon "Transito.app" 175 120 \
        --hide-extension "Transito.app" \
        --app-drop-link 425 120 \
        "$DIST_NAME-macOS.dmg" \
        "$DIST_NAME/"
else
    echo "create-dmg not found. Creating ZIP instead..."
    zip -r "$DIST_NAME-macOS.zip" "$DIST_NAME/"
fi

# Create CLI ZIP
echo "Creating CLI ZIP..."
cd "$DIST_NAME/cli"
zip -r "../$DIST_NAME-CLI.zip" .
cd ../..

# Clean up
rm -rf "$DIST_NAME"

echo "✅ Distribution packages created:"
echo "  - ${DIST_NAME}-macOS.dmg (or .zip)"
echo "  - ${DIST_NAME}-CLI.zip"
echo ""
echo "To distribute:"
echo "  - Share the DMG/ZIP files"
echo "  - CLI users should extract and run install.sh first"
echo "  - GUI users can drag Transito.app to Applications"
