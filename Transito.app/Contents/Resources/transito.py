#!/usr/bin/env python3
import argparse
import os
import shlex
import subprocess
import sys
from urllib.parse import urlparse

VERSION = "v0.1.0"


def which(bin_name: str) -> str | None:
    from shutil import which as _which
    return _which(bin_name)


def guess_name(url: str, ext: str) -> str:
    path = urlparse(url).path
    base = os.path.basename(path).replace('.m3u8', '').replace('.M3U8', '')
    return (base or 'out') + f'.{ext}'


def build_headers(args) -> list[str]:
    pairs = []
    if args.user_agent:
        pairs.append(f'User-Agent: {args.user_agent}')
    if args.referer:
        pairs.append(f'Referer: {args.referer}')
    if pairs:
        return ["-headers", "\\r\\n".join(pairs) + "\\r\\n"]
    return []


def main():
    p = argparse.ArgumentParser()
    p.add_argument('url')
    p.add_argument('output', nargs='?')
    p.add_argument('--user-agent')
    p.add_argument('--referer')
    p.add_argument('--dry-run', action='store_true')
    args = p.parse_args()

    url = args.url
    out = args.output

    if which('ffmpeg') is None:
        print('ffmpeg not found. Install it with: brew install ffmpeg')
        sys.exit(1)

    if not out:
        out = guess_name(url, 'mp4')

    extra = build_headers(args)
    cmd = [
        'ffmpeg', '-hide_banner', '-loglevel', 'warning', '-nostdin',
        *extra,
        '-i', url,
        '-c', 'copy', '-bsf:a', 'aac_adtstoasc', '-movflags', '+faststart',
        out,
    ]

    pretty = ' '.join(shlex.quote(x) for x in cmd)
    print(f'Transito {VERSION} — Writing to: {out}')
    print(f'Transito {VERSION} — Running: {pretty}')

    if args.dry_run:
        return

    proc = subprocess.Popen(cmd, stderr=subprocess.STDOUT, stdout=subprocess.PIPE, text=True)
    try:
        for line in proc.stdout:
            sys.stdout.write(line)
    except KeyboardInterrupt:
        proc.terminate()
    finally:
        code = proc.wait()
        if code == 0:
            print(f"\n✅ Done: {out}")
        else:
            print(f"\n❌ ffmpeg exited with code {code}", file=sys.stderr)
            sys.exit(code)


if __name__ == '__main__':
    main()