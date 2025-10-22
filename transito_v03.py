#!/usr/bin/env python3
import argparse
import os
import shlex
import subprocess
import sys
from pathlib import Path

from transito_engine import (
    build_ffmpeg_video_args,
    build_ffmpeg_subtitle_args,
    get_subtitle_output_path,
)

VERSION = "v0.3.0"


def which(bin_name: str) -> str | None:
    from shutil import which as _which
    return _which(bin_name)


def main():
    p = argparse.ArgumentParser(
        description="Transito - HLS Downloader",
        prog="transito"
    )
    p.add_argument('url', help='HLS playlist URL (.m3u8)')
    p.add_argument(
        '-o', '--output',
        required=True,
        help='Output MP4 file path'
    )
    p.add_argument(
        '--user-agent',
        help='Custom User-Agent header'
    )
    p.add_argument(
        '--referer',
        help='Referer header (often required for authenticated streams)'
    )
    p.add_argument(
        '--extract-subtitles',
        action='store_true',
        help='Extract subtitles as separate .vtt file'
    )
    p.add_argument(
        '--open-on-complete',
        action='store_true',
        help='Open the downloaded file when complete'
    )
    p.add_argument(
        '--dry-run',
        action='store_true',
        help='Show command without executing'
    )
    
    args = p.parse_args()
    url = args.url
    output_mp4 = args.output

    if which('ffmpeg') is None:
        print('ffmpeg not found. Install it with: brew install ffmpeg')
        sys.exit(1)

    # Build video download command
    video_cmd = build_ffmpeg_video_args(
        url,
        output_mp4,
        user_agent=args.user_agent,
        referer=args.referer,
    )

    pretty_cmd = ' '.join(shlex.quote(x) for x in video_cmd)
    print(f'Transito {VERSION}')
    print(f'URL: {url}')
    print(f'Output: {output_mp4}')
    
    if args.extract_subtitles:
        output_vtt = get_subtitle_output_path(output_mp4)
        print(f'Subtitles: {output_vtt}')
    
    print()
    print(f'Running: {pretty_cmd}')

    if args.dry_run:
        if args.extract_subtitles:
            subtitle_cmd = build_ffmpeg_subtitle_args(
                url,
                get_subtitle_output_path(output_mp4),
                user_agent=args.user_agent,
                referer=args.referer,
            )
            pretty_sub_cmd = ' '.join(shlex.quote(x) for x in subtitle_cmd)
            print(f'Then: {pretty_sub_cmd}')
        return

    # Download video
    proc = subprocess.Popen(
        video_cmd,
        stderr=subprocess.STDOUT,
        stdout=subprocess.PIPE,
        text=True
    )
    try:
        for line in proc.stdout:
            sys.stdout.write(line)
    except KeyboardInterrupt:
        proc.terminate()
    finally:
        code = proc.wait()
        if code != 0:
            print(f"\n❌ ffmpeg exited with code {code}", file=sys.stderr)
            sys.exit(code)

    print(f"\n✅ Video downloaded: {output_mp4}")

    # Extract subtitles if requested
    if args.extract_subtitles:
        output_vtt = get_subtitle_output_path(output_mp4)
        print(f"\nExtracting subtitles to {output_vtt}...")
        
        subtitle_cmd = build_ffmpeg_subtitle_args(
            url,
            output_vtt,
            user_agent=args.user_agent,
            referer=args.referer,
        )
        
        pretty_sub_cmd = ' '.join(shlex.quote(x) for x in subtitle_cmd)
        print(f'Running: {pretty_sub_cmd}')
        
        proc = subprocess.Popen(
            subtitle_cmd,
            stderr=subprocess.STDOUT,
            stdout=subprocess.PIPE,
            text=True
        )
        try:
            for line in proc.stdout:
                sys.stdout.write(line)
        except KeyboardInterrupt:
            proc.terminate()
        finally:
            code = proc.wait()
            if code != 0:
                print(f"\n⚠️  Subtitle extraction failed with code {code}", file=sys.stderr)
            else:
                print(f"✅ Subtitles extracted: {output_vtt}")

    # Open file if requested
    if args.open_on_complete:
        import platform
        if platform.system() == 'Darwin':
            os.system(f'open "{output_mp4}"')
        elif platform.system() == 'Linux':
            os.system(f'xdg-open "{output_mp4}"')
        elif platform.system() == 'Windows':
            os.startfile(output_mp4)

    print(f"\n✅ Done!")


if __name__ == '__main__':
    main()
