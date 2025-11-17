# Building Transito v0.4.0

This guide explains how to build the native macOS Transito app from source.

## Prerequisites

### Required
- **macOS 13.0+** (Ventura or later)
- **Xcode 14.0+** with Command Line Tools
- **Swift 5.9+** (included with Xcode)

### Optional
- **ffmpeg** (for testing downloads)
  ```bash
  brew install ffmpeg
  ```

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/pedrobritx/Transito.git
   cd Transito
   ```

2. **Open in Xcode**
   ```bash
   open packages/macos/Transito.xcodeproj
   ```

3. **Build and run**
   - Press `⌘R` to build and run
   - Or use Product → Run from the menu

## Building from Command Line

### Debug Build
```bash
cd packages/macos
xcodebuild -project Transito.xcodeproj \
           -scheme Transito \
           -configuration Debug \
           -derivedDataPath build \
           build
```

### Release Build
```bash
./scripts/build_swift_app.sh
```

This will create a production-ready `Transito.app` in the repository root.

## Project Structure

```
packages/macos/
├── Transito.xcodeproj/          # Xcode project
└── Transito/                     # Source files
    ├── TransitoApp.swift         # App entry point
    ├── ContentView.swift         # Main UI
    ├── HLSEngine.swift           # Download engine
    ├── DownloadManager.swift     # Download state management
    ├── FFmpegInstaller.swift     # ffmpeg auto-installer
    ├── PreferencesView.swift     # Settings UI
    ├── URLDiscoveryManager.swift # URL discovery (placeholder)
    ├── URLDiscoveryView.swift    # URL discovery UI
    ├── VisualEffectView.swift    # Native effects wrapper
    ├── Assets.xcassets/          # App icon and assets
    ├── Info.plist                # App metadata
    └── Transito.entitlements     # App capabilities
```

## Swift Files Overview

### Core Engine
- **HLSEngine.swift** (200 lines)
  - Native Swift download implementation
  - ffmpeg process management
  - Progress tracking
  - Error handling

### UI Components
- **ContentView.swift** (144 lines)
  - Main app interface
  - Drag-and-drop support
  - Download controls

- **PreferencesView.swift** (70 lines)
  - Settings and preferences
  - Default paths
  - ffmpeg status

### Managers
- **DownloadManager.swift** (165 lines)
  - Download state management
  - Notification handling
  - Progress coordination

- **FFmpegInstaller.swift** (133 lines)
  - Automatic ffmpeg installation
  - Binary download and setup
  - PATH management

### Utilities
- **VisualEffectView.swift** (21 lines)
  - Native blur effects wrapper
  - AppKit bridge for SwiftUI

## Build Configuration

### Info.plist Settings
- **Bundle Identifier**: `com.transito.hls-downloader`
- **Version**: `0.4.0`
- **Minimum macOS**: `13.0`
- **Document Types**: M3U8 files

### Capabilities
- Network access (for downloads)
- File system access (for saving)
- Notifications (for completion alerts)

## Testing

### Manual Testing Checklist
1. **Launch App**
   - App opens without errors
   - Window displays correctly

2. **Download Test**
   - Paste a test M3U8 URL
   - Select output location
   - Click Download
   - Verify progress updates
   - Check completion notification

3. **Drag-and-Drop Test**
   - Drag M3U8 URL from browser
   - Verify URL is populated
   - Test download

4. **Error Handling**
   - Test with invalid URL
   - Test with inaccessible URL
   - Verify error messages

5. **ffmpeg Integration**
   - Test with ffmpeg installed
   - Test without ffmpeg (should offer to install)

### Test URLs
For testing, you can use any valid M3U8 URL. Example sources:
- Apple's test streams
- Your own test content
- Public streaming services (respect ToS)

## Troubleshooting

### Build Errors

**"Swift Compiler Error"**
- Ensure you're using Xcode 14.0+
- Clean build folder: Product → Clean Build Folder
- Quit and restart Xcode

**"Code signing failed"**
- Change signing to "Sign to Run Locally"
- Or use your own developer certificate

**"Missing SDK"**
- Install Xcode Command Line Tools:
  ```bash
  xcode-select --install
  ```

### Runtime Issues

**App crashes on launch**
- Check Console.app for crash logs
- Verify macOS version is 13.0+
- Try building in Debug mode for better error messages

**ffmpeg not found**
- Install manually: `brew install ffmpeg`
- App should auto-detect it on next launch

**Download fails**
- Verify URL is a valid M3U8 file
- Check internet connection
- Verify ffmpeg is installed and working

## Distribution

### Creating a Release Package

1. **Build release version**
   ```bash
   ./scripts/build_swift_app.sh
   ```

2. **Create DMG or ZIP**
   ```bash
   ./scripts/release.sh
   ```

3. **Test the package**
   - Install on a clean macOS system
   - Verify app launches
   - Test download functionality

### Code Signing (Optional)

For wider distribution:
1. Get an Apple Developer certificate
2. Sign the app:
   ```bash
   codesign --deep --force --sign "Developer ID Application: Your Name" Transito.app
   ```
3. Notarize with Apple (for Gatekeeper)

## Development Tips

### Xcode Shortcuts
- `⌘R` - Build and run
- `⌘B` - Build only
- `⌘.` - Stop
- `⌘K` - Clean build folder
- `⌘/` - Toggle comment

### Debugging
- Use `print()` statements for quick debugging
- Set breakpoints in Xcode
- Use LLDB for advanced debugging
- Check Console.app for system logs

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Keep files focused and modular
- Add comments for complex logic

## Contributing

When contributing:
1. Test your changes thoroughly
2. Follow existing code style
3. Update documentation if needed
4. Test on a clean macOS install
5. Submit a pull request

## Support

- **Issues**: [GitHub Issues](https://github.com/pedrobritx/Transito/issues)
- **Discussions**: Use GitHub Discussions for questions

## License

MIT License - see LICENSE file for details
