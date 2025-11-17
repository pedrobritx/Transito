# Transito URL Discovery Guide

Transito can download videos from HLS (m3u8) streams. For best results, provide the direct m3u8 URL. For page URLs, Transito tries automatic discovery.

## Automatic Discovery (3 Tiers)

### Tier 1: Built-in HTML Scraper (No Prerequisites)

Works for sites that embed m3u8 URLs directly in HTML.

```bash
python3 transito.py "https://example.com/video-page" -o video.mp4
```

**Supported patterns:**

- Direct `.m3u8` URLs in `<source>`, `<video>`, or `<script>` tags
- Kaltura playManifest URLs in page source
- Some sites with static player configs

**Limitations:**

- Does NOT work for JavaScript-loaded players (like Descomplica, Vimeo, etc.)
- Does NOT work for DRM-protected content

---

### Tier 2: yt-dlp Integration (Recommended for JS-Heavy Sites)

Works for 1000+ video sites including YouTube, Vimeo, Kaltura, and more.

**Install:**

```bash
brew install yt-dlp    # macOS
# or
pip install yt-dlp     # any OS
```

**Usage:**

```bash
python3 transito.py "https://aulas.descomplica.com.br/.../aula/..." -o video.mp4
```

Transito automatically calls `yt-dlp -g` to discover the m3u8, then downloads with ffmpeg.

**Pros:**

- Handles JavaScript players
- Supports 1000+ sites
- Fast and reliable

**Cons:**

- Requires external tool installation

---

### Tier 3: Manual Discovery (Always Works)

Use browser DevTools to find the m3u8 URL manually.

**Steps:**

1. Open the video page in your browser
2. Open DevTools (Cmd+Option+I on macOS, F12 on Windows/Linux)
3. Go to Network tab
4. Filter by "m3u8"
5. Play the video
6. Copy the .m3u8 URL that appears
7. Use it with Transito:

```bash
python3 transito.py "https://cdn.example.com/.../playlist.m3u8" -o video.mp4
```

**Pros:**

- Always works (no dependencies)
- You control exactly what's downloaded
- Works with any site

**Cons:**

- Manual step required
- Need to repeat for each video

---

## Helper Script (Optional)

For advanced users, `transito_discover.py` provides Playwright-based browser automation:

```bash
# Install Playwright (optional)
pip install playwright
playwright install chromium

# Discover m3u8 automatically
python3 transito_discover.py "https://example.com/video-page"

# Use with Transito
python3 transito.py "$(python3 transito_discover.py 'https://example.com/video-page')" -o video.mp4
```

---

## Recommendations by Use Case

| Use Case                         | Recommended Method                   |
| -------------------------------- | ------------------------------------ |
| Quick one-off download           | Manual (Tier 3)                      |
| Regular downloads from same site | Install yt-dlp (Tier 2)              |
| Sites with direct m3u8 in HTML   | Built-in scraper (Tier 1)            |
| Automation/scripting             | yt-dlp (Tier 2) or Playwright helper |

---

## Troubleshooting

### "Invalid data found when processing input"

- The URL is not a valid m3u8 playlist
- Use manual discovery or install yt-dlp

### "403 Forbidden" or "401 Unauthorized"

- Add headers: `--user-agent "..." --referer "https://..."`
- The m3u8 may have expired session tokens (get a fresh one)

### "No m3u8 found in page HTML"

- The site uses JavaScript to load the player
- Install yt-dlp or use manual discovery

### DRM-Protected Content

- Transito cannot download DRM-protected streams (Widevine, FairPlay, etc.)
- Legal downloads only!

---

## For Developers

Want to add support for a specific site? Edit `resolve_url()` in `transito.py` to add custom regex patterns or API calls for that site's player.
