# Transito - HLS Downloader

A hybrid HLS (.m3u8) downloader available as both a lightweight CLI tool and a native macOS app.

## Architecture

This repository contains multiple packages:

- **`packages/core/`** — Standalone CLI tool (`transito`) used by both interfaces
- **`packages/macos/`** — Native SwiftUI macOS app with drag-drop and notifications
- **`packages/homebrew/`** — Homebrew formula for CLI installation
- **`scripts/`** — Build and distribution scripts

## Installation Options

### Option 1: CLI Tool (Recommended for Terminal Users)

**Via Homebrew:**

```bash
brew install transito
```

**Manual Installation:**

```bash
# Install dependencies
brew install python ffmpeg

# Download and install CLI tool
curl -L https://github.com/yourusername/transito/releases/latest/download/transito-cli.zip -o transito-cli.zip
unzip transito-cli.zip
sudo cp transito /usr/local/bin/
sudo chmod +x /usr/local/bin/transito
```

### Option 2: Native macOS App (Recommended for GUI Users)

**Download and Install:**

1. Download `Transito-macOS.dmg` from [releases](https://github.com/yourusername/transito/releases)
2. Open the DMG and drag `Transito.app` to Applications
3. Launch from Applications or Spotlight

**Features:**

- Drag-drop M3U8 URLs
- Native macOS notifications
- Auto-downloads ffmpeg on first launch
- Beautiful SwiftUI interface

## Usage

### CLI Usage

```bash
# Basic download
transito https://example.com/playlist.m3u8

# Specify output file
transito https://example.com/playlist.m3u8 output.mp4

# With custom headers
transito --user-agent "Custom UA" --referer "https://ref.com" https://example.com/playlist.m3u8

# Show progress
transito --progress https://example.com/playlist.m3u8

# Dry run (show command without executing)
transito --dry-run https://example.com/playlist.m3u8
```

### GUI Usage

1. **Launch Transito.app**
2. **Paste or drag-drop** an M3U8 URL
3. **Choose output location** (optional)
4. **Click Download** and watch progress
5. **Get notified** when complete

## Requirements

- **macOS 13.0+** (for SwiftUI app)
- **Python 3.10+** (for CLI tool)
- **ffmpeg + ffprobe** (auto-installed by GUI, manual install for CLI)

## Development

### Building from Source

**CLI Tool:**

```bash
# Test the core CLI tool
./packages/core/transito --help
```

**macOS App:**

```bash
# Build SwiftUI app
./scripts/build_swift_app.sh

# Or build Python-based app bundle
./scripts/build_macos_app.sh
```

**Distribution Packages:**

```bash
# Create all distribution packages
./scripts/release.sh
```

### Project Structure

```
transito/
├── packages/
│   ├── core/              # CLI tool (Python)
│   │   ├── transito       # Main executable
│   │   └── setup.py       # Package metadata
│   ├── macos/             # SwiftUI app
│   │   ├── Transito.xcodeproj
│   │   └── Transito/      # Swift source files
│   └── homebrew/          # Homebrew formula
│       └── transito.rb
├── scripts/               # Build scripts
├── VERSION
└── README.md
```

## Key Features

- **Stream-copy downloads** (no re-encoding)
- **Progress tracking** with time estimates
- **Custom headers** support (User-Agent, Referer)
- **Auto-reconnection** for unstable streams
- **Cross-platform CLI** (works on Linux/Windows too)
- **Native macOS integration** (notifications, drag-drop, file associations)

## Troubleshooting

**CLI Issues:**

- `ffmpeg not found`: Run `brew install ffmpeg`
- `Permission denied`: Run `sudo chmod +x /usr/local/bin/transito`

**GUI Issues:**

- App won't launch: Check macOS version (13.0+ required)
- ffmpeg download fails: Check internet connection, try CLI installation
- Notifications not working: Check System Preferences > Notifications

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test both CLI and GUI
5. Submit a pull request

## License

MIT License - see LICENSE file for details.
