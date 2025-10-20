# Changelog

All notable changes to Transito will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
