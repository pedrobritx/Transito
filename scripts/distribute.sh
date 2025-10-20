#!/bin/bash

# Transito Distribution Script
# Creates a distributable ZIP file of the macOS app

set -e

APP_NAME="Transito"
VERSION=$(cat VERSION)
DIST_NAME="${APP_NAME}-${VERSION}-macOS"

echo "Creating distribution package for ${APP_NAME} ${VERSION}..."

# Ensure the app bundle exists
if [ ! -d "${APP_NAME}.app" ]; then
    echo "App bundle not found. Running build script..."
    ./build_app.sh
fi

# Create distribution directory
if [ -d "$DIST_NAME" ]; then
    rm -rf "$DIST_NAME"
fi

mkdir -p "$DIST_NAME"

# Copy app bundle
cp -R "${APP_NAME}.app" "$DIST_NAME/"

# Copy documentation
cp README.md "$DIST_NAME/"

# Create a simple installer script
cat > "$DIST_NAME/install.sh" << 'EOF'
#!/bin/bash

echo "Installing Transito..."
echo ""

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install dependencies
echo "Installing dependencies..."
brew install python ffmpeg

# Check Python version and install appropriate tkinter
PYTHON_VERSION=$(python3 --version | cut -d' ' -f2 | cut -d'.' -f1,2)
echo "Installing python-tk@${PYTHON_VERSION}..."
brew install "python-tk@${PYTHON_VERSION}" || echo "Tkinter may already be installed"

echo ""
echo "✅ Installation complete!"
echo "You can now run Transito.app"
EOF

chmod +x "$DIST_NAME/install.sh"

# Create ZIP file
echo "Creating ZIP distribution..."
zip -r "${DIST_NAME}.zip" "$DIST_NAME" >/dev/null

# Clean up
rm -rf "$DIST_NAME"

echo "✅ Distribution package created: ${DIST_NAME}.zip"
echo ""
echo "To distribute:"
echo "  - Share the ZIP file"
echo "  - Users should extract and run install.sh first"
echo "  - Then they can run Transito.app"
