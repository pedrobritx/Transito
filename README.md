# HLS Downloader

A tiny single-file GUI downloader for HLS (.m3u8) streams that wraps ffmpeg.

This project provides a minimal Tkinter-based GUI (`hls_gui.py`) which uses
`ffmpeg`/`ffprobe` to download and package HLS streams to MP4 or MKV without
re-encoding. The script is intentionally self-contained and includes light
checks to help macOS users install missing dependencies via Homebrew.

## Features

- Paste an `.m3u8` URL.
- Choose destination and filename (Save As...).
- Progress bar and log output (uses `ffmpeg -progress`).
- Attempts to help install `ffmpeg` / `ffprobe` and `python-tk` on macOS.

## Requirements

- macOS (tested conceptually; works on other platforms with Python/Tkinter and ffmpeg)
- Python 3.10+ (3.13 recommended via Homebrew on recent macOS)
- ffmpeg and ffprobe available on PATH
- Tkinter available for the Python installation (GUI)

On macOS it's easiest to use Homebrew to install missing components.

## Quick start (macOS)

1. Install Homebrew (if you don't have it):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install Python and ffmpeg (if needed):

```bash
# Install Python 3
brew install python

# Install ffmpeg
brew install ffmpeg

# If tkinter is missing for the Homebrew Python build, install the matching package
# (the script will suggest the correct package name, e.g. python-tk@3.13):
brew install python-tk@3.13
```

3. Run the GUI:

```bash
python3 "hls_gui.py"
```

The script will also detect missing `ffmpeg`/`ffprobe` or `python-tk` and offer
to install them via Homebrew when run interactively.

## Usage

1. Paste an `.m3u8` URL into the URL field.
2. Click "Choose…" to pick output folder and filename (or leave default).
3. Click "Download". Progress and logs will appear in the window.

The output file will be written without re-encoding (stream copy). For MP4 the
script applies the `aac_adtstoasc` bitstream filter and `+faststart` movflag to
make the file streamable.

## Troubleshooting

- "Tkinter not available": If you see this, install Python from python.org or
  use Homebrew's `python` and install `python-tk@<version>` (the GUI will
  suggest the matching package).
- "ffmpeg not found": Install via Homebrew: `brew install ffmpeg`.
- Permission errors writing to the destination: pick a folder under your
  home directory, or run the script with appropriate permissions.

## Development notes

- The main script is `hls_gui.py` and is intentionally a single-file app so you
  can copy it to another machine easily.
- There's also a small CLI helper `m3u8_dl.py` included for command-line use.

## License

This repository does not include a license file. Add a LICENSE if you want to
set reuse terms.

## Contributing

Open a PR with improvements. Small, well-documented changes are welcome.
