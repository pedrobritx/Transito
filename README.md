# Transito - HLS Downloader for macOS

A native macOS app for downloading HLS (.m3u8) video streams with a beautiful SwiftUI interface.

## ✨ Features

- 🎨 **Modern SwiftUI Interface** - Liquid glass design with vibrancy effects
- 📥 **Simple Drag & Drop** - Paste m3u8 URLs and choose your output folder
- 📊 **Real-time Progress** - See download progress with detailed stream info
- 🔔 **Native Notifications** - Get notified when downloads complete
- ⚙️ **Preferences** - Customize default folder, headers, and auto-open behavior
- 📝 **Subtitle Extraction** - Optionally extract WebVTT subtitles alongside video
- 🚀 **Auto-Setup** - ffmpeg installed automatically on first launch

## 🎯 What's New in v0.3.0

- Complete UI redesign with liquid glass SwiftUI interface
- Subtitle extraction support (.vtt files)
- User preferences with persistent settings
- Enhanced download notifications
- Custom headers (User-Agent, Referer)
- Improved error handling and feedback

## 📦 Installation

### Download Pre-built App

1. Download `Transito.app.zip` from [releases](https://github.com/pedrobritx/Transito/releases)
2. Unzip and drag `Transito.app` to your Applications folder
3. Launch from Applications or Spotlight

### Build from Source

```bash
# Clone the repository
git clone https://github.com/pedrobritx/Transito.git
cd Transito

# Build with Xcode
xcodebuild -project packages/macos/Transito/Transito.xcodeproj \
  -scheme Transito -configuration Release

# Or use the build script
./scripts/build_swift_app.sh
```

## 🚀 Usage

1. **Launch Transito** from Applications
2. **Paste M3U8 URL** - Direct link to the video manifest
3. **Choose Output Folder** - Where to save the downloaded video
4. **Configure Options** (optional):
   - Enable subtitle extraction
   - Set custom headers if needed
5. **Click Download** - Watch real-time progress
6. **Get Notified** - Receive a notification when complete

### Finding M3U8 URLs

Most video sites load m3u8 URLs dynamically. To find them:

1. Open the video page in Safari
2. Open Web Inspector (`Cmd+Option+I`)
3. Go to Network tab
4. Play the video
5. Filter by "m3u8"
6. Copy the URL from the request
7. Paste into Transito

## ⚙️ Preferences

Access via `Transito` → `Settings` or `Cmd+,`:

- **Default Output Folder** - Where videos are saved by default
- **Custom User-Agent** - Override default browser identification
- **Custom Referer** - Set referer header for downloads
- **Auto-open Files** - Automatically open videos when complete

## 🛠️ Requirements

- **macOS 12.0+** (Monterey or later)
- **Xcode 14+** (for building from source)
- **ffmpeg** - Automatically installed on first launch

## 📋 Architecture

```
Transito/
├── packages/macos/Transito/     # SwiftUI macOS app source
│   ├── TransitoApp.swift        # App entry point
│   ├── ContentView.swift        # Main UI (liquid glass design)
│   ├── DownloadManager.swift    # Download orchestration
│   ├── PreferencesView.swift    # Settings window
│   ├── VisualEffectView.swift   # Glass material effects
│   └── FFmpegInstaller.swift    # Auto ffmpeg setup
├── scripts/                     # Build automation
│   ├── build_swift_app.sh       # Xcode build script
│   └── build_macos_app.sh       # Package .app bundle
└── .github/workflows/           # CI/CD automation
    └── release.yml              # Automated releases
```

## 🐛 Troubleshooting

### "App is damaged and can't be opened"

macOS Gatekeeper may block unsigned apps. To bypass:

```bash
xattr -cr /Applications/Transito.app
```

Or right-click the app, select "Open", and confirm.

### ffmpeg Not Found

Transito installs ffmpeg automatically on first launch. If this fails:

```bash
brew install ffmpeg
```

### Download Fails with "Invalid data"

- Ensure you're using a direct .m3u8 URL (not a webpage)
- Try adding custom headers if the site requires authentication
- Check that the m3u8 URL is still valid (some have expiring session tokens)

### Subtitles Not Extracted

- Subtitle extraction requires the stream to contain WebVTT subtitle tracks
- Check ffmpeg output for errors
- Not all streams include subtitle data

## 🤝 Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details

## 🙏 Acknowledgments

- Built with SwiftUI and ffmpeg
- Inspired by the need for a simple, native macOS HLS downloader
- Thanks to the open-source community

---

**Made with ❤️ for macOS**

- Progress tracking with duration estimates
- Visual feedback and status updates
- Error logging in the console area
- Open folder button when download completes

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

```text
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
