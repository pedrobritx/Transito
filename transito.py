#!/usr/bin/env python3

import argparse
import csv
import os
import re
import shlex
import subprocess
import sys
import urllib.error
import urllib.request
from urllib.parse import urljoin, urlparse

VERSION = "v0.3.0"


def which(bin_name: str) -> str | None:
    """Find executable in PATH."""
    from shutil import which as _which
    return _which(bin_name)


def guess_output_filename(url: str, ext: str = "mp4") -> str:
    """Guess output filename from URL."""
    try:
        path = urlparse(url).path
        base = os.path.basename(path)
        if base.lower().endswith(".m3u8"):
            base = base[:-5]
        if not base:
            base = "video"
        return f"{base}.{ext}"
    except Exception:
        return f"video.{ext}"


def resolve_url(url: str, headers: dict | None = None) -> str:
    """
    Resolve URL to m3u8 manifest by scraping HTML if necessary.
    
    If the URL ends with .m3u8, return it as-is.
    Otherwise, try:
    1. Scrape HTML for direct m3u8 links
    2. Extract Kaltura partner/entry IDs to construct playManifest URL
    3. Fall back to yt-dlp if available (handles JS-heavy sites)
    
    Returns the discovered m3u8 URL or the original URL if none found.
    """
    parsed = urlparse(url)
    # If already a manifest, return as-is
    if parsed.path.lower().endswith('.m3u8'):
        return url
    
    # Fetch the page HTML
    req_headers = {
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
    }
    if headers:
        if headers.get("User-Agent"):
            req_headers["User-Agent"] = headers["User-Agent"]
        if headers.get("Referer"):
            req_headers["Referer"] = headers["Referer"]
    
    try:
        request = urllib.request.Request(url, headers=req_headers)
        with urllib.request.urlopen(request, timeout=15) as response:
            html = response.read().decode("utf-8", errors="ignore")
    except Exception as e:
        print(f"Warning: Failed to fetch page for URL resolution: {e}", file=sys.stderr)
        return url
    
    # Search for <video src="...m3u8..."> tags first (most reliable)
    video_src_pattern = r'<video[^>]+src=["\']([^"\']+\.m3u8[^"\']*)["\']'
    video_matches = re.findall(video_src_pattern, html, re.IGNORECASE | re.DOTALL)
    
    candidates = []
    
    # Prioritize <video> tag sources
    for match in video_matches:
        candidate = match.strip()
        if not candidate.startswith('http'):
            candidate = urljoin(url, candidate)
        candidates.append(candidate)
        print(f"→ Found in <video> tag: {candidate}", file=sys.stderr)
    
    # If no <video> tags, try other patterns
    if not candidates:
        patterns = [
            # Direct Kaltura playManifest URLs
            r'(https?://[^"\'\s]+/playManifest/[^"\'\s]+\.m3u8[^"\'\s]*)',
            # Generic .m3u8 URLs in quotes or data attributes
            r'(https?://[^"\'\s]+\.m3u8[^"\'\s]*)',
            # Source tags
            r'<source[^>]+src=["\']([^"\']+\.m3u8[^"\']*)["\']',
            # Relative paths
            r'["\']([^"\']+\.m3u8[^"\'\s]*)["\']',
        ]
        
        for pattern in patterns:
            matches = re.findall(pattern, html, re.IGNORECASE | re.DOTALL)
            for match in matches:
                candidate = match[0] if isinstance(match, tuple) else match
                candidate = candidate.strip('\'"')
                if not candidate.startswith('http'):
                    candidate = urljoin(url, candidate)
                candidates.append(candidate)
    
    if candidates:
        discovered = candidates[0]
        print(f"→ Discovered m3u8: {discovered}", file=sys.stderr)
        return discovered
    
    # Try to extract Kaltura partner ID and entry ID to construct playManifest URL
    partner_match = re.search(r'/p/(\d+)/', html)
    entry_match = re.search(r'(?:entry_?[iI]d|entryId)["\':=\s]+["\']?([0-9a-zA-Z_]+)', html)
    
    if partner_match and entry_match:
        partner_id = partner_match.group(1)
        entry_id = entry_match.group(1)
        constructed = f"https://cdnapisec.kaltura.com/p/{partner_id}/sp/{partner_id}00/playManifest/entryId/{entry_id}/protocol/https/format/applehttp/a.m3u8"
        print(f"→ Constructed Kaltura m3u8 from entry {entry_id}: {constructed}", file=sys.stderr)
        return constructed
    
    # Try yt-dlp as fallback (if available)
    ytdlp_bin = which('yt-dlp')
    if ytdlp_bin:
        print(f"→ Trying yt-dlp to resolve URL...", file=sys.stderr)
        try:
            result = subprocess.run(
                [ytdlp_bin, '-g', '--no-warnings', url],
                capture_output=True,
                text=True,
                timeout=30
            )
            if result.returncode == 0 and result.stdout.strip():
                lines = result.stdout.strip().splitlines()
                # yt-dlp -g returns direct URLs (may be multiple for video+audio)
                # Prefer .m3u8 URLs if present
                m3u8_urls = [line for line in lines if '.m3u8' in line.lower()]
                if m3u8_urls:
                    print(f"→ yt-dlp found m3u8: {m3u8_urls[0]}", file=sys.stderr)
                    return m3u8_urls[0]
                # Otherwise return first URL
                if lines:
                    print(f"→ yt-dlp found direct URL: {lines[0]}", file=sys.stderr)
                    return lines[0]
        except Exception as e:
            print(f"Warning: yt-dlp failed: {e}", file=sys.stderr)
    
    # No m3u8 found, provide helpful guidance
    print(f"", file=sys.stderr)
    print(f"❌ Could not auto-discover m3u8 from page URL", file=sys.stderr)
    print(f"", file=sys.stderr)
    print(f"Quick fix: Find the m3u8 URL manually:", file=sys.stderr)
    print(f"  1. Open the page in your browser", file=sys.stderr)
    print(f"  2. Open DevTools (Cmd+Option+I on macOS)", file=sys.stderr)
    print(f"  3. Go to Network tab, filter by 'm3u8'", file=sys.stderr)
    print(f"  4. Play the video and copy the .m3u8 URL", file=sys.stderr)
    print(f"  5. Run: transito '<M3U8_URL>' -o video.mp4", file=sys.stderr)
    print(f"", file=sys.stderr)
    print(f"Or install yt-dlp for automatic resolution:", file=sys.stderr)
    print(f"  brew install yt-dlp   (macOS)", file=sys.stderr)
    print(f"  pip install yt-dlp    (any OS)", file=sys.stderr)
    print(f"", file=sys.stderr)
    
    # Return original URL (will likely fail, but ffmpeg error will be clear)
    return url


def get_subtitle_output_path(mp4_path: str) -> str:
    """Get subtitle output path from MP4 path."""
    base, _ = os.path.splitext(mp4_path)
    return f"{base}.vtt"


def _parse_attribute_line(line: str) -> dict[str, str]:
    """Parse an HLS tag attribute list into a dict."""
    reader = csv.reader([line])
    attrs: dict[str, str] = {}
    for row in reader:
        for item in row:
            if "=" not in item:
                continue
            key, value = item.split("=", 1)
            value = value.strip()
            if value.startswith('"') and value.endswith('"'):
                value = value[1:-1]
            attrs[key.strip()] = value
    return attrs


def _safe_int(value: str | None) -> int | None:
    try:
        return int(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _safe_float(value: str | None) -> float | None:
    try:
        return float(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _parse_master_playlist(text: str) -> tuple[list[dict], dict[str, list[dict]]]:
    """Extract variant and audio tracks from a master playlist."""
    variants: list[dict] = []
    audio_groups: dict[str, list[dict]] = {}
    lines = [line.strip() for line in text.splitlines()]

    for idx, line in enumerate(lines):
        if line.startswith("#EXT-X-STREAM-INF"):
            attrs = _parse_attribute_line(line.split(":", 1)[1] if ":" in line else "")
            uri = None
            cursor = idx + 1
            while cursor < len(lines):
                candidate = lines[cursor].strip()
                cursor += 1
                if not candidate or candidate.startswith("#"):
                    continue
                uri = candidate
                break
            if not uri:
                continue

            width = height = None
            resolution = attrs.get("RESOLUTION")
            if resolution and "x" in resolution.lower():
                parts = resolution.lower().split("x", 1)
                if len(parts) == 2:
                    width = _safe_int(parts[0])
                    height = _safe_int(parts[1])

            variants.append(
                {
                    "uri": uri,
                    "width": width,
                    "height": height,
                    "bandwidth": _safe_int(attrs.get("BANDWIDTH")),
                    "frame_rate": _safe_float(attrs.get("FRAME-RATE")),
                    "audio": attrs.get("AUDIO"),
                    "raw": attrs,
                }
            )
        elif line.startswith("#EXT-X-MEDIA"):
            attrs = _parse_attribute_line(line.split(":", 1)[1] if ":" in line else "")
            if attrs.get("TYPE") != "AUDIO":
                continue
            group_id = attrs.get("GROUP-ID")
            uri = attrs.get("URI")
            if not group_id or not uri:
                continue
            entry = {
                "uri": uri,
                "name": attrs.get("NAME"),
                "default": attrs.get("DEFAULT", "NO").upper() == "YES",
                "language": attrs.get("LANGUAGE"),
            }
            audio_groups.setdefault(group_id, []).append(entry)

    return variants, audio_groups


def _pick_best_variant(variants: list[dict]) -> dict | None:
    if not variants:
        return None

    def sort_key(item: dict) -> tuple[int, int, int, float]:
        height = item.get("height") or 0
        width = item.get("width") or 0
        bandwidth = item.get("bandwidth") or 0
        frame_rate = item.get("frame_rate") or 0.0
        return (height, width, bandwidth, frame_rate)

    return max(variants, key=sort_key)


def prepare_hls_inputs(url: str, headers: dict | None = None) -> tuple[list[str], dict | None]:
    """Select the best matching media playlists for the given master URL."""
    req_headers = {}
    if headers:
        if headers.get("User-Agent"):
            req_headers["User-Agent"] = headers["User-Agent"]
        if headers.get("Referer"):
            req_headers["Referer"] = headers["Referer"]

    try:
        request = urllib.request.Request(url, headers=req_headers)
        with urllib.request.urlopen(request, timeout=15) as response:
            text = response.read().decode("utf-8", errors="ignore")
    except Exception:
        return [url], None

    if "#EXT-X-STREAM-INF" not in text:
        return [url], None

    variants, audio_groups = _parse_master_playlist(text)
    chosen = _pick_best_variant(variants)
    if not chosen:
        return [url], None

    video_url = urljoin(url, chosen["uri"])
    audio_url = None
    audio_group = chosen.get("audio")
    if audio_group and audio_group in audio_groups:
        candidates = audio_groups[audio_group]
        preferred = next((entry for entry in candidates if entry.get("default")), None)
        selected_audio = preferred or (candidates[0] if candidates else None)
        if selected_audio and selected_audio.get("uri"):
            audio_url = urljoin(url, selected_audio["uri"])

    info = {
        "width": chosen.get("width"),
        "height": chosen.get("height"),
        "bandwidth": chosen.get("bandwidth"),
        "frame_rate": chosen.get("frame_rate"),
        "audio_group": audio_group,
        "video_url": video_url,
        "audio_url": audio_url,
    }

    inputs = [video_url]
    if audio_url and audio_url not in inputs:
        inputs.append(audio_url)

    return inputs, info


def build_ffmpeg_command(inputs: list[str], output: str, headers: dict = None) -> list[str]:
    """Build ffmpeg command for HLS download."""
    cmd: list[str] = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-nostdin"]

    header_value = None
    if headers:
        header_pairs = []
        if headers.get("User-Agent"):
            header_pairs.append(f"User-Agent: {headers['User-Agent']}")
        if headers.get("Referer"):
            header_pairs.append(f"Referer: {headers['Referer']}")
        if header_pairs:
            header_value = "\\r\\n".join(header_pairs) + "\\r\\n"

    for input_url in inputs:
        cmd.extend(["-reconnect", "1", "-reconnect_streamed", "1", "-reconnect_delay_max", "30"])
        if header_value:
            cmd.extend(["-headers", header_value])
        cmd.extend(["-i", input_url])

    cmd.extend(["-map", "0:v?"])
    if len(inputs) > 1:
        cmd.extend(["-map", "1:a?"])
    else:
        cmd.extend(["-map", "0:a?"])

    cmd.extend([
        "-c", "copy",
        "-bsf:a", "aac_adtstoasc",
        "-movflags", "+faststart",
        output,
    ])

    return cmd


def build_ffmpeg_subtitle_command(url: str, output: str, headers: dict = None) -> list[str]:
    """Build ffmpeg command to extract subtitles from HLS."""
    cmd: list[str] = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-nostdin"]

    header_value = None
    if headers:
        header_pairs = []
        if headers.get("User-Agent"):
            header_pairs.append(f"User-Agent: {headers['User-Agent']}")
        if headers.get("Referer"):
            header_pairs.append(f"Referer: {headers['Referer']}")
        if header_pairs:
            header_value = "\\r\\n".join(header_pairs) + "\\r\\n"

    cmd.extend(["-reconnect", "1", "-reconnect_streamed", "1", "-reconnect_delay_max", "30"])
    if header_value:
        cmd.extend(["-headers", header_value])
    cmd.extend(["-i", url])

    # Extract first subtitle stream as WebVTT
    cmd.extend([
        "-map", "0:s:0?",
        "-c:s", "webvtt",
        "-f", "webvtt",
        output,
    ])

    return cmd


def main():
    parser = argparse.ArgumentParser(
        description="Transito - HLS Downloader CLI",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  transito https://example.com/playlist.m3u8 -o output.mp4
  transito https://example.com/playlist.m3u8 -o output.mp4 --extract-subtitles
  transito --user-agent "Custom UA" --referer "https://ref.com" https://example.com/playlist.m3u8 -o video.mp4
        """
    )
    parser.add_argument('url', help='M3U8 playlist URL')
    parser.add_argument('-o', '--output', help='Output MP4 filename')
    parser.add_argument('--user-agent', help='Custom User-Agent header')
    parser.add_argument('--referer', help='Custom Referer header')
    parser.add_argument('--extract-subtitles', action='store_true', help='Extract subtitles as .vtt file')
    parser.add_argument('--progress', action='store_true', help='Show progress output')
    parser.add_argument('--dry-run', action='store_true', help='Show command without executing')
    parser.add_argument('--version', action='version', version=f'Transito {VERSION}')
    
    args = parser.parse_args()
    
    # Check if ffmpeg is available
    if which('ffmpeg') is None:
        print('Error: ffmpeg not found. Install it with: brew install ffmpeg', file=sys.stderr)
        sys.exit(1)
    
    headers = {}
    if args.user_agent:
        headers['User-Agent'] = args.user_agent
    if args.referer:
        headers['Referer'] = args.referer

    if not args.output:
        args.output = guess_output_filename(args.url)

    # Resolve page URL to m3u8 if necessary
    resolved_url = resolve_url(args.url, headers)

    inputs, variant_info = prepare_hls_inputs(resolved_url, headers)
    cmd = build_ffmpeg_command(inputs, args.output, headers)
    pretty_cmd = ' '.join(shlex.quote(x) for x in cmd)
    
    print(f'Transito {VERSION} — Writing to: {args.output}')
    
    if args.extract_subtitles:
        output_vtt = get_subtitle_output_path(args.output)
        print(f'Transito {VERSION} — Subtitles to: {output_vtt}')
    
    if variant_info:
        stream_bits = []
        if variant_info.get("width") and variant_info.get("height"):
            stream_bits.append(f"{variant_info['width']}x{variant_info['height']}")
        if variant_info.get("bandwidth"):
            kbps = variant_info['bandwidth'] / 1000
            stream_bits.append(f"{kbps:.0f} kbps")
        if variant_info.get("frame_rate"):
            stream_bits.append(f"{variant_info['frame_rate']:.2f} fps")
        if stream_bits:
            print(f"Transito {VERSION} — Selected stream: {', '.join(stream_bits)}")
    
    print(f'Transito {VERSION} — Running: {pretty_cmd}')
    
    if args.dry_run:
        if args.extract_subtitles:
            sub_cmd = build_ffmpeg_subtitle_command(resolved_url, get_subtitle_output_path(args.output), headers)
            pretty_sub_cmd = ' '.join(shlex.quote(x) for x in sub_cmd)
            print(f'Transito {VERSION} — Then: {pretty_sub_cmd}')
        return 0
    
    # Download video
    proc = subprocess.Popen(
        cmd,
        stderr=subprocess.STDOUT,
        stdout=subprocess.PIPE,
        text=True,
        bufsize=1,
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

    print(f"\n✅ Video downloaded: {args.output}")

    # Extract subtitles if requested
    if args.extract_subtitles:
        output_vtt = get_subtitle_output_path(args.output)
        print(f"\nExtracting subtitles to {output_vtt}...")
        
        sub_cmd = build_ffmpeg_subtitle_command(resolved_url, output_vtt, headers)
        pretty_sub_cmd = ' '.join(shlex.quote(x) for x in sub_cmd)
        print(f'Running: {pretty_sub_cmd}')
        
        proc = subprocess.Popen(
            sub_cmd,
            stderr=subprocess.STDOUT,
            stdout=subprocess.PIPE,
            text=True,
            bufsize=1,
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

    print(f"\n✅ All done!")


if __name__ == '__main__':
    main()
