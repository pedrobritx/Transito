# Transito M3U8 Finder Bookmarklet

**One-click m3u8 discovery for Safari, Chrome, and Firefox**

## What is this?

A tiny JavaScript bookmarklet that finds m3u8 video URLs on any page and copies them to your clipboard, ready to use with Transito.

## ✨ Installation (One-Time Setup)

### Safari

1. Show the Favorites Bar: `View` → `Show Favorites Bar` (or `Cmd+Shift+B`)
2. Create a new bookmark (`Cmd+D`)
3. Name it: **"Find M3U8"**
4. Copy the code from `transito_bookmarklet_minified.txt` (one line)
5. Paste it as the URL
6. Save to Favorites Bar

### Chrome/Edge

1. Show the Bookmarks Bar: `View` → `Always Show Bookmarks Bar` (or `Cmd+Shift+B`)
2. Right-click the bookmarks bar → `Add Page`
3. Name: **"Find M3U8"**
4. Copy the code from `transito_bookmarklet_minified.txt`
5. Paste as URL
6. Save

### Firefox

1. Show the Bookmarks Toolbar: `View` → `Toolbars` → `Bookmarks Toolbar`
2. `Bookmarks` → `Show All Bookmarks` (or `Cmd+Shift+O`)
3. Right-click → `New Bookmark`
4. Name: **"Find M3U8"**
5. Copy code from `transito_bookmarklet_minified.txt`
6. Paste as Location
7. Save

## 🚀 Usage

1. Navigate to a video page (e.g., Descomplica, Kaltura, etc.)
2. **Wait for the video player to load**
3. Click the **"Find M3U8"** bookmarklet in your toolbar
4. The m3u8 URL is automatically copied to your clipboard!
5. Paste it into Transito:

```bash
python3 transito.py "<PASTE_URL_HERE>" -o video.mp4
```

Or drag the page to the Transito macOS app and paste the URL when prompted.

## 📋 Example Workflow

**Before (Manual Inspector):**

1. Open Inspector (`Cmd+Option+I`)
2. Search for "m3u8"
3. Find `<video>` tag
4. Copy `src` attribute
5. Paste into Transito

**After (Bookmarklet):**

1. Click "Find M3U8" bookmark
2. Paste into Transito

**Time saved: ~30 seconds per video!**

## What It Does

The bookmarklet searches for m3u8 URLs in:

- `<video src="...">` tags
- `<source src="...">` tags
- Entire page HTML (catches dynamically loaded URLs)

If multiple m3u8 URLs are found, it prompts you to choose which one to copy.

## 🛠️ Generating the Minified Version

To create `transito_bookmarklet_minified.txt`:

```bash
# Remove comments and minify (manual for now)
cat transito_bookmarklet.js | \
  sed '/^\/\//d' | \
  tr -d '\n' | \
  sed 's/  */ /g' > transito_bookmarklet_minified.txt

# Add javascript: prefix
echo "javascript:$(cat transito_bookmarklet_minified.txt)" > transito_bookmarklet_minified.txt
```

Or use an online minifier: https://javascript-minifier.com/

## 🎯 Supported Sites

Works on any site with m3u8 video streams:

- ✅ Kaltura (Descomplica, etc.)
- ✅ Brightcove
- ✅ JW Player
- ✅ Video.js
- ✅ HLS.js players
- ✅ Custom HTML5 video players

## ⚠️ Limitations

- Requires the video player to have loaded (JavaScript must have run)
- Won't work on DRM-protected streams
- Some sites obfuscate m3u8 URLs (try yt-dlp instead)

## 🔄 Alternative: yt-dlp

For fully automatic discovery without clicking bookmarklets:

```bash
brew install yt-dlp
python3 transito.py "<PAGE_URL>" -o video.mp4
```

Transito will automatically call yt-dlp to discover the m3u8.

## 📦 Bundle with macOS App

To integrate this into the Transito macOS app:

1. Add a Safari extension with this bookmarklet
2. Or add a "Find m3u8" button that runs a WKWebView script
3. Or provide install instructions in the app's Help menu

---

**Made for Transito v0.3.0**  
Simplifying HLS downloads, one click at a time.
