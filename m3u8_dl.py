#!/usr/bin/env python3
import argparse, os, shlex, subprocess, sys
from urllib.parse import urlparse

def which(bin_name: str) -> str | None:
    for p in os.environ.get("PATH","").split(os.pathsep):
        cand = os.path.join(p, bin_name)
        if os.path.isfile(cand) and os.access(cand, os.X_OK):
            return cand
    return None

def guess_name(url: str, ext: str) -> str:
    path = urlparse(url).path
    base = os.path.basename(path).replace(".m3u8","").replace(".M3U8","")
    return (base or "out") + f".{ext}"

def build_headers(args) -> list[str]:
    headers = []
    pairs = []
    if args.user_agent:
        pairs.append(f"User-Agent: {args.user_agent}")
    if args.referer:
        pairs.append(f"Referer: {args.referer}")
    if args.cookies:
        pairs.append(f"Cookie: {args.cookies}")
    for h in (args.header or []):
        pairs.append(h)
    if pairs:
        # ffmpeg expects CRLF-delimited header blob
        headers = ["-headers", "$'" + "\\r\\n".join(pairs) + "\\r\\n'"]
    return headers

def is_local_m3u8(url: str) -> bool:
    return url.startswith("file:") or url.startswith("/") or url.startswith("./") or url.startswith("../")

def main():
    ap = argparse.ArgumentParser(description="Download HLS (.m3u8) to MP4/MKV via ffmpeg (no re-encode).")
    ap.add_argument("url", help="Remote or local .m3u8 URL/path")
    ap.add_argument("-o","--output", help="Output filename (default: inferred from URL)")
    ap.add_argument("--mkv", action="store_true", help="Use MKV container instead of MP4")
    ap.add_argument("--subs", action="store_true", help="Include subtitles (as mov_text for MP4)")
    ap.add_argument("--user-agent", help="Custom User-Agent header")
    ap.add_argument("--referer", help="Referer header")
    ap.add_argument("--cookies", help="Cookie header value (e.g. 'foo=bar; baz=qux')")
    ap.add_argument("-H","--header", action="append",
                    help="Extra header lines, e.g. -H 'X-Token: abc'. Can repeat.")
    ap.add_argument("--no-reconnect", action="store_true", help="Disable ffmpeg reconnect flags")
    ap.add_argument("--loglevel", default="info", help="ffmpeg loglevel (quiet, error, warning, info)")
    ap.add_argument("--dry-run", action="store_true", help="Print ffmpeg command and exit")
    args = ap.parse_args()

    if which("ffmpeg") is None:
        print("Error: ffmpeg not found in PATH. Install it (e.g., `brew install ffmpeg`).", file=sys.stderr)
        sys.exit(127)

    ext = "mkv" if args.mkv else "mp4"
    out = args.output or guess_name(args.url, ext)
    out = os.path.abspath(out)

    cmd = ["ffmpeg", "-hide_banner", "-loglevel", args.loglevel]

    if not args.no-reconnect:
        cmd += ["-reconnect", "1", "-reconnect_streamed", "1", "-reconnect_delay_max", "30"]

    if is_local_m3u8(args.url):
        # Allow local playlist that references http(s) segments
        cmd += ["-protocol_whitelist", "file,http,https,tcp,tls,crypto"]

    cmd += build_headers(args)
    cmd += ["-i", args.url, "-map", "0", "-c", "copy"]

    if not args.mkv:
        # Make MP4 happier with AAC-in-ADTS and faststart
        cmd += ["-bsf:a", "aac_adtstoasc", "-movflags", "+faststart"]
        if args.subs:
            # Convert subs so MP4 can carry them
            cmd += ["-c:s", "mov_text"]
    else:
        # MKV: no need for bitstream filter; keep subs as-is
        pass

    cmd += [out]

    # Pretty-print command (with shell-safe quoting)
    pretty = " ".join(shlex.quote(x) for x in cmd)
    print(f"→ Writing to: {out}")
    print(f"→ Running: {pretty}")

    if args.dry_run:
        return

    # Run ffmpeg and stream its output
    proc = subprocess.Popen(cmd, stderr=subprocess.STDOUT, stdout=subprocess.PIPE, text=True)
    try:
        for line in proc.stdout:  # type: ignore
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

if __name__ == "__main__":
    main()