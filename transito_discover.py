#!/usr/bin/env python3
"""
Transito URL Discovery Helper
Resolves page URLs to direct m3u8 manifests using browser automation.
Optional dependency: playwright (install with: pip install playwright && playwright install chromium)
"""

import sys
import subprocess
import json


def discover_with_playwright(url: str) -> str | None:
    """Use Playwright to load page and capture m3u8 network requests."""
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("Error: playwright not installed", file=sys.stderr)
        print("Install with: pip install playwright && playwright install chromium", file=sys.stderr)
        return None
    
    m3u8_url = None
    
    def handle_request(request):
        nonlocal m3u8_url
        if '.m3u8' in request.url.lower() and not m3u8_url:
            m3u8_url = request.url
    
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            page = browser.new_page()
            
            # Capture network requests
            page.on("request", handle_request)
            
            # Navigate and wait for player to load
            page.goto(url, wait_until="networkidle", timeout=30000)
            
            # Give player time to start
            page.wait_for_timeout(3000)
            
            browser.close()
            
        return m3u8_url
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return None


def discover_with_ytdlp(url: str) -> str | None:
    """Use yt-dlp to extract direct m3u8 URL."""
    try:
        result = subprocess.run(
            ['yt-dlp', '-g', '--no-warnings', url],
            capture_output=True,
            text=True,
            timeout=30
        )
        if result.returncode == 0 and result.stdout.strip():
            lines = result.stdout.strip().splitlines()
            m3u8_urls = [line for line in lines if '.m3u8' in line.lower()]
            if m3u8_urls:
                return m3u8_urls[0]
            if lines:
                return lines[0]
    except FileNotFoundError:
        pass
    except Exception as e:
        print(f"yt-dlp error: {e}", file=sys.stderr)
    return None


def main():
    if len(sys.argv) < 2:
        print("Usage: transito_discover.py <page_url>", file=sys.stderr)
        print("", file=sys.stderr)
        print("Discovers direct m3u8 URL from a video page.", file=sys.stderr)
        print("Tries yt-dlp first, then Playwright if available.", file=sys.stderr)
        sys.exit(1)
    
    url = sys.argv[1]
    
    # Try yt-dlp first (faster, no browser needed)
    print("→ Trying yt-dlp...", file=sys.stderr)
    m3u8 = discover_with_ytdlp(url)
    if m3u8:
        print(f"✓ Found (yt-dlp): {m3u8}", file=sys.stderr)
        print(m3u8)
        return 0
    
    # Fall back to Playwright
    print("→ Trying Playwright...", file=sys.stderr)
    m3u8 = discover_with_playwright(url)
    if m3u8:
        print(f"✓ Found (playwright): {m3u8}", file=sys.stderr)
        print(m3u8)
        return 0
    
    print("", file=sys.stderr)
    print("❌ Could not discover m3u8 URL", file=sys.stderr)
    print("", file=sys.stderr)
    print("Manual method:", file=sys.stderr)
    print("  1. Open page in browser", file=sys.stderr)
    print("  2. DevTools → Network → filter 'm3u8'", file=sys.stderr)
    print("  3. Play video and copy the .m3u8 URL", file=sys.stderr)
    sys.exit(1)


if __name__ == '__main__':
    main()
