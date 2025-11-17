# Changelog

All notable changes to Transito will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2025-11-17

### 🎉 Major Release - Native Swift Implementation

This release represents a complete rewrite of Transito in native Swift, removing all Python dependencies and providing a truly native macOS experience.

### Added
- Native Swift HLSEngine for downloading streams
- Complete Swift implementation of ffmpeg integration
- Improved progress tracking with real-time updates
- Better error handling and user feedback

### Changed
- **BREAKING**: Removed Python-based CLI tool
- **BREAKING**: Now macOS-only (13.0+)
- Migrated from hybrid Python/Swift to pure Swift codebase
- Updated to follow Apple Human Interface Guidelines
- Streamlined UI with cleaner, more intuitive interface
- Improved app architecture with modern Swift concurrency

### Removed
- Python dependencies and scripts
- CLI tool (app is now macOS GUI-only)
- Unnecessary version displays in UI
- Legacy Python engine code

### Technical Details
- Built with Swift 5.9+ and SwiftUI
- Uses modern async/await for download operations
- Native Process execution for ffmpeg
- Improved memory management and performance

## [0.3.1] - Previous Release

### Added
- macOS-first focus with SwiftUI interface
- Drag-and-drop support for M3U8 URLs
- Native macOS notifications
- Automatic ffmpeg installation

### Changed
- Improved user interface design
- Better progress feedback

## Earlier Versions

See git history for details on versions prior to 0.3.1.

---

[0.4.0]: https://github.com/pedrobritx/Transito/releases/tag/v0.4.0
[0.3.1]: https://github.com/pedrobritx/Transito/releases/tag/v0.3.1
