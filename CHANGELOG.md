# Changelog

All notable changes to Transito will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2024-01-XX

### ✨ Added

#### UI/UX Redesign

- **Liquid Glass Design**: Beautiful macOS 14+ glass effect with AngularGradient accents
- **SwiftUI Native App**: Replaced legacy Tkinter GUI with modern SwiftUI interface
- **Visual Effects**: NSVisualEffectView materials (.hudWindow, .thinMaterial, .ultraThinMaterial) with vibrancy
- **Improved Layout**: Clean card-based design with proper spacing and visual hierarchy
- **Accessibility**: Full VoiceOver support, proper labels, hints, and focus management

#### Subtitle Extraction

- **`--extract-subtitles` CLI Flag**: Save WebVTT subtitle files alongside MP4 downloads
- **Automatic Output Path**: Subtitles saved as `.vtt` with same basename as output file
- **Separate Extraction Process**: Runs WebVTT extraction after main download completes
- **Graceful Fallback**: Continues if subtitle stream unavailable

#### Preferences & Persistence

- **Native Settings Window**: Accessible via Cmd+, or menu (Transito → Settings)
- **UserDefaults Storage**: Persistent user preferences across app launches
  - Default download folder with picker button
  - Custom User-Agent header
  - Custom Referer header
  - Auto-open downloaded files toggle
- **Clean Form UI**: Organized settings with labels and descriptions

#### CLI Enhancements

- **HLS Variant Selection**: Automatic best-quality variant detection from master playlists
- **Audio Track Selection**: Intelligent audio group and default track picking
- **Stream Metadata Display**: Shows selected resolution, bitrate, and FPS before download
- **Improved Header Support**: Custom User-Agent and Referer headers via CLI flags
- **Dry-Run Mode**: `--dry-run` shows complete ffmpeg commands without executing
- **Version Output**: `--version` shows v0.3.0

#### Notifications & Feedback

- **UserNotifications**: Native macOS notifications on completion/failure
- **Real-Time Progress**: Live progress bar with visual status updates
- **Error Display**: Inline error messages with full context
- **Open on Complete**: Option to automatically launch downloaded files

#### Engine Improvements

- **Shared Python Engine**: New `transito_engine.py` module for CLI and app code sharing
- **Robust HLS Parsing**: CSV-based attribute parsing for EXT-X-STREAM-INF and EXT-X-MEDIA tags
- **Better Error Recovery**: Configurable reconnection and timeout parameters
- **Progress Parsing**: Real-time ffmpeg progress pipe integration

### 🔧 Changed

- **Version Bump**: Updated to v0.3.0 across all packages
- **transito.py**: Now uses `-o/--output` flags with proper argument parsing
- **Info.plist**: Updated CFBundleShortVersionString to 0.3.0
- **Engine Refactoring**: Consolidated ffmpeg builders into reusable functions
- **CLI Architecture**: Cleaner separation of concerns with transito_engine.py

### ✅ Fixed

- Maintained WebVTT codec error fix from v0.2.0 (`-map 0:v? -map 0:a?`)
- Proper subprocess communication with ffmpeg progress pipe
- Correct header handling in subtitle extraction commands

### 📦 Technical Details

- **New Files**:

  - `transito_engine.py`: Shared HLS parsing and ffmpeg builders
  - `VisualEffectView.swift`: NSViewRepresentable glass material wrapper
  - `PreferencesView.swift`: UserDefaults-backed settings form
  - `CHANGELOG.md`: This file

- **Updated Files**:
  - `transito.py`: Version bump, subtitle extraction, improved CLI
  - `ContentView.swift`: Complete liquid glass redesign
  - `DownloadManager.swift`: Subtitle extraction, notifications, headers
  - `TransitoApp.swift`: Window setup, preferences scene
  - `VERSION`: 0.2.0 → 0.3.0
  - `Info.plist`: Bundle version update

### 🐛 Known Limitations

- Subtitle extraction requires ffmpeg 4.1+ with WebVTT encoder
- Progress precision depends on ffmpeg `-progress` output accuracy
- macOS Notifications require User Notification Center opt-in

---

## [0.2.0] - 2024-10-20

### Fixed

- **Critical Fix**: Resolved WebVTT subtitle codec error that prevented video downloads from HLS streams containing subtitles
  - Changed ffmpeg mapping from `-map 0` to `-map 0:v? -map 0:a?`
  - Now only maps video and audio streams, excluding incompatible subtitle streams
  - Fixes error: "Could not find tag for codec webvtt in stream #0"

### Changed

- Added reconnection parameters to CLI for improved reliability with unstable streams
  - `-reconnect 1 -reconnect_streamed 1 -reconnect_delay_max 30`
- Updated all version strings across CLI, GUI, and app bundle to v0.2.0

### Technical Details

- Applied fix to all 6 code locations:
  - Root CLI (`transito.py`)
  - Root GUI (`transito_gui.py`)
  - Core package (`packages/core/transito`)
  - macOS package (`packages/macos/Transito/transito`)
  - Bundled CLI (`Transito.app/Contents/Resources/transito`)
  - Bundled GUI (`Transito.app/Contents/Resources/transito_gui.py`)

## [0.1.0] - 2024-10-20

### Added

- Initial release of Transito HLS Downloader
- CLI tool for terminal-based downloads
- GUI application with Tkinter interface
- macOS app bundle for easy installation
- Support for custom headers (User-Agent, Referer)
- Progress tracking with duration estimates
- Dry-run mode for command preview
- Auto-detection of ffmpeg/ffprobe
- Stream-copy downloads (no re-encoding)
- Fast-start optimization for MP4 files

### Features

- **Dual Interface**: Both CLI and GUI modes
- **Cross-Platform**: CLI works on macOS, Linux, Windows
- **Native macOS App**: Double-click to launch GUI
- **Progress Tracking**: Real-time progress with time estimates
- **Error Handling**: Detailed error messages and logging
- **Reconnection**: Automatic reconnection for unstable streams
