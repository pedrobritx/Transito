#!/usr/bin/env python3
"""
Transito Download Engine
Provides shared ffmpeg command builders for video and subtitle extraction.
"""

import os
from pathlib import Path
from typing import Optional, List


def build_ffmpeg_video_args(
    url: str,
    output_path: str,
    user_agent: Optional[str] = None,
    referer: Optional[str] = None,
) -> List[str]:
    """
    Build ffmpeg command args for video/audio extraction (skip WebVTT).
    
    Args:
        url: HLS playlist URL
        output_path: Output MP4 file path
        user_agent: Optional User-Agent header
        referer: Optional Referer header
    
    Returns:
        List of ffmpeg command arguments
    """
    args = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel", "warning",
        "-nostdin",
        "-reconnect", "1",
        "-reconnect_streamed", "1",
        "-reconnect_delay_max", "30",
    ]
    
    # Add headers if provided
    headers = []
    if user_agent:
        headers.append(f"User-Agent: {user_agent}")
    if referer:
        headers.append(f"Referer: {referer}")
    
    if headers:
        args.extend(["-headers", "\\r\\n".join(headers) + "\\r\\n"])
    
    # Input
    args.extend(["-i", url])
    
    # Map only video and audio (skip subtitles)
    args.extend(["-map", "0:v?", "-map", "0:a?"])
    
    # Encoding and optimization
    args.extend([
        "-c", "copy",  # Stream copy (no re-encoding)
        "-bsf:a", "aac_adtstoasc",
        "-movflags", "+faststart",
        "-progress", "pipe:1",
    ])
    
    # Output file
    args.append(str(output_path))
    
    return args


def build_ffmpeg_subtitle_args(
    url: str,
    output_vtt_path: str,
    user_agent: Optional[str] = None,
    referer: Optional[str] = None,
) -> List[str]:
    """
    Build ffmpeg command args for subtitle extraction.
    
    Args:
        url: HLS playlist URL
        output_vtt_path: Output .vtt file path
        user_agent: Optional User-Agent header
        referer: Optional Referer header
    
    Returns:
        List of ffmpeg command arguments
    """
    args = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel", "warning",
        "-nostdin",
        "-reconnect", "1",
        "-reconnect_streamed", "1",
        "-reconnect_delay_max", "30",
    ]
    
    # Add headers if provided
    headers = []
    if user_agent:
        headers.append(f"User-Agent: {user_agent}")
    if referer:
        headers.append(f"Referer: {referer}")
    
    if headers:
        args.extend(["-headers", "\\r\\n".join(headers) + "\\r\\n"])
    
    # Input
    args.extend(["-i", url])
    
    # Map only subtitle streams
    args.extend(["-map", "0:s?"])
    
    # Subtitle codec and format
    args.extend([
        "-c:s", "webvtt",
        "-f", "webvtt",
    ])
    
    # Output file
    args.append(str(output_vtt_path))
    
    return args


def get_subtitle_output_path(mp4_path: str) -> str:
    """
    Generate subtitle file path from MP4 path.
    
    Example: /path/to/video.mp4 -> /path/to/video.vtt
    """
    p = Path(mp4_path)
    return str(p.with_suffix(".vtt"))


if __name__ == "__main__":
    # Example usage
    url = "https://example.com/playlist.m3u8"
    output_mp4 = "/tmp/video.mp4"
    
    video_args = build_ffmpeg_video_args(url, output_mp4)
    print("Video command:")
    print(" ".join(video_args))
    
    output_vtt = get_subtitle_output_path(output_mp4)
    subtitle_args = build_ffmpeg_subtitle_args(url, output_vtt)
    print("\nSubtitle command:")
    print(" ".join(subtitle_args))
