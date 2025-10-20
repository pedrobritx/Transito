# Transito - HLS Downloader

A tiny single-file GUI downloader for HLS (.m3u8) streams that wraps ffmpeg.

This repository contains:

- `transito_gui.py` — single-file Tkinter GUI that uses `ffmpeg`/`ffprobe` to
  download HLS to MP4/MKV without re-encoding.
- `transito.py` — a small command-line helper for scripted downloads.

Key design goals:

- Single-file GUI for easy copy-to-machine distribution.
- Minimal dependencies (Python + ffmpeg). On macOS the script can help install
  missing tools via Homebrew.

## Highlights

- Paste an `.m3u8` URL and click Download.
- Save As flow for choosing destination and renaming.
- Progress bar driven by `ffmpeg -progress` and a log window for ffmpeg output.
- Optional auto-install helpers for Homebrew (opt-in only).

## Requirements

- Python 3.10+ (Homebrew Python recommended on macOS)
- ffmpeg + ffprobe on PATH
- Tkinter available for the chosen Python interpreter

On macOS, Homebrew simplifies installing missing pieces.

## Install & run (macOS)

Install Homebrew if needed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install dependencies (interactive):

```bash
brew install python ffmpeg
# If Tkinter is missing for your Homebrew Python, install python-tk@<version>.
# The GUI can auto-suggest the correct version (e.g., 3.14 or 3.13) and install it.
# Example:
#   brew install python-tk@3.14
```

Run the GUI:

```bash
python3 transito_gui.py
```

Auto-install (non-interactive):

```bash
# using environment variable
HLS_DOWNLOADER_AUTO_INSTALL=1 python3 transito_gui.py

# or using CLI flag
python3 transito_gui.py --auto-install
```

The auto-install feature is opt-in. When enabled the script will run Homebrew
installs automatically (no user prompts).

Run the CLI helper:

```bash
python3 transito.py "https://example.com/path/playlist.m3u8" [output.mp4]
# Optional headers:
python3 transito.py --user-agent "UA" --referer "https://ref.example" "https://.../playlist.m3u8"
```

## Building the macOS App

To build your own macOS app bundle:

```bash
./build_app.sh
open Transito.app
```

To create a distributable package:

```bash
./distribute.sh
```

The macOS app includes:

- Native app bundle with proper icon
- Automatic dependency checking
- User-friendly error dialogs for missing tools
- Support for .m3u8 file associations

## Usage

1. Paste a `.m3u8` URL into the field.
2. (Optional) Click "Choose…" to pick output path and filename.
3. Click "Download" and watch progress in the bar and the log.

The script streams the input and performs stream-copy; the resulting MP4/MKV
is not re-encoded.

## Release notes & changelog

This repository uses a lightweight changelog maintained in `README.md` for now.

### Unreleased

- Improve GUI: add prereq installer and macOS-friendly Tkinter handling
- Add README and auto-install opt-in

### v0.1.0 — Initial public release

- Basic GUI downloader and CLI helper

## Releasing a new version

Suggested minimal release checklist:

1. Bump version in README/changelog.
2. Run a quick smoke test on a clean macOS environment (Homebrew Python).
3. Tag the commit: `git tag -a v0.1.0 -m "v0.1.0"` and push tags: `git push --tags`.
4. Create a GitHub release from the tag.

## Troubleshooting

- Tkinter missing: use Homebrew's `python` and install `python-tk@<version>` that
  matches your `python3 --version` (e.g., `python-tk@3.14`). The GUI can auto-install
  it when run with `--auto-install` or `HLS_DOWNLOADER_AUTO_INSTALL=1`.
- ffmpeg missing: `brew install ffmpeg`.

## Contributing

PRs welcome. Keep changes small and documented.

## License

Add a LICENSE file if you want to set reuse terms.
