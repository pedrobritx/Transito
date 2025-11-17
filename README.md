# Transito - HLS Downloader

A native macOS app built with Swift and SwiftUI for downloading HLS (.m3u8) streams.

## Features

- **Native macOS App** — Built entirely with Swift and SwiftUI
- **Drag & Drop** — Simply drag M3U8 URLs into the app
- **Progress Tracking** — Real-time download progress with time estimates
- **Native Notifications** — macOS notifications when downloads complete
- **Custom Headers** — Support for User-Agent and Referer headers
- **Auto-reconnection** — Handles unstable streams gracefully
- **Stream-copy downloads** — No re-encoding for faster processing

## Installation

### Download from GitHub

1. Download `Transito.app` from [releases](https://github.com/pedrobritx/Transito/releases)
2. Drag `Transito.app` to your Applications folder
3. Launch from Applications or Spotlight
4. On first launch, the app will offer to download ffmpeg if not already installed

## Requirements

- **macOS 13.0+** (Ventura or later)
- **ffmpeg** — Auto-installed on first launch, or install manually with `brew install ffmpeg`

## Usage

1. **Launch Transito.app**
2. **Paste or drag-drop** an M3U8 URL into the URL field
3. **Choose output location** using the "Choose..." button
4. **Click Download** and watch the progress
5. **Get notified** when the download completes

## Building from Source

### Requirements

- Xcode 14.0+
- macOS 13.0+ SDK

### Build Steps

```bash
# Clone the repository
git clone https://github.com/pedrobritx/Transito.git
cd Transito

# Open in Xcode
open packages/macos/Transito.xcodeproj

# Build and run from Xcode (⌘R)
```

## Architecture

Transito is built with a modern Swift architecture:

- **TransitoApp.swift** — Main app entry point
- **ContentView.swift** — Primary UI with drag-drop support
- **HLSEngine.swift** — Core download engine using ffmpeg
- **DownloadManager.swift** — Manages download state and notifications
- **FFmpegInstaller.swift** — Handles automatic ffmpeg installation

## Troubleshooting

**App won't launch:**
- Check macOS version (requires 13.0+)
- Check Console.app for any error messages

**ffmpeg download fails:**
- Check internet connection
- Install manually: `brew install ffmpeg`
- The app will detect ffmpeg in standard locations

**Notifications not working:**
- Go to System Settings > Notifications
- Find Transito and enable notifications

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Distribution

This app is distributed through GitHub releases only, not through the Mac App Store.

## License

MIT License - see LICENSE file for details.

## Version

Current version: v0.4.0
