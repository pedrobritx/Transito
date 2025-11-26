# Transito - HLS Downloader

A native macOS application for downloading HLS (.m3u8) video streams.

## Overview

Transito is a powerful, native macOS application built with SwiftUI that allows you to download HLS streams directly to your computer. It features a modern, drag-and-drop interface and uses a custom native engine for high-performance downloads.

## Features

- **Native macOS Experience**: Built with SwiftUI for a seamless look and feel.
- **Drag & Drop**: Simply drag an .m3u8 URL onto the app to start downloading.
- **Stream Copy**: Downloads streams without re-encoding for maximum quality and speed.
- **Auto-Retry**: Automatically handles network interruptions and reconnects.
- **Notifications**: Get notified when your download completes.

## Installation

1. Download the latest release (`Transito-v0.5.0.dmg`).
2. Open the DMG file.
3. Drag **Transito.app** to your **Applications** folder.

## Usage

1. Launch **Transito** from your Applications folder.
2. Paste an M3U8 URL into the input field OR drag a URL from your browser into the window.
3. Click **Download**.
4. The video will be saved to your chosen output directory (default: Downloads).

## Development

### Requirements

- macOS 13.0+
- Xcode 14.0+
- ffmpeg (automatically handled by the app, but useful for development)

### Building from Source

1. Clone the repository.
2. Run the build script:

```bash
./scripts/build_swift_app.sh
```

3. To create a distributable DMG:

```bash
./scripts/create_dmg.sh
```

### Project Structure

```text
transito/
├── packages/
│   └── macos/             # SwiftUI app source
│       ├── Transito.xcodeproj
│       └── Transito/      # Swift source files
├── scripts/               # Build and packaging scripts
├── VERSION
└── README.md
```

## License

MIT License - see LICENSE file for details.
