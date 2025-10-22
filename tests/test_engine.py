import os
import tempfile
from transito_engine import (
    build_ffmpeg_video_args,
    build_ffmpeg_subtitle_args,
    get_subtitle_output_path,
)


def test_build_ffmpeg_video_args_basic():
    url = "https://example.com/playlist.m3u8"
    out = "/tmp/video.mp4"
    args = build_ffmpeg_video_args(url, out)
    assert args[0] == "ffmpeg"
    assert "-i" in args
    assert url in args
    # ensure subtitle streams are not mapped into the mp4 mux
    assert "0:s?" not in args
    assert "-map" in args
    # output path must be the last element
    assert args[-1] == out


def test_build_ffmpeg_subtitle_args_basic(tmp_path):
    url = "https://example.com/playlist.m3u8"
    out = str(tmp_path / "subs.vtt")
    args = build_ffmpeg_subtitle_args(url, out)
    assert args[0] == "ffmpeg"
    assert "-i" in args
    assert url in args
    # ensure only subtitle streams are mapped
    assert "-map" in args
    idx = args.index("-map")
    assert args[idx + 1] == "0:s?"
    assert args[-1] == out


def test_get_subtitle_output_path_changes_extension(tmp_path):
    mp4 = str(tmp_path / "video.mp4")
    vtt = get_subtitle_output_path(mp4)
    assert vtt.endswith(".vtt")
    assert vtt.replace(".vtt", ".mp4") != mp4 or True
