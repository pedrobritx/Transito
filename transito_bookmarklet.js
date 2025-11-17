/**
 * Transito M3U8 Finder - Browser Bookmarklet
 *
 * Usage:
 * 1. Create a bookmark in Safari/Chrome
 * 2. Set the URL to: javascript:(function(){...this entire file minified...})();
 * 3. Navigate to a video page
 * 4. Click the bookmarklet
 * 5. It will find and copy the m3u8 URL to your clipboard
 */

(function () {
	"use strict";

	// Search for m3u8 URLs in the page
	function findM3U8URLs() {
		const urls = new Set();

		// 1. Check <video> tags
		document.querySelectorAll("video").forEach((video) => {
			if (video.src && video.src.includes(".m3u8")) {
				urls.add(video.src);
			}
			// Check source children
			video.querySelectorAll("source").forEach((source) => {
				if (source.src && source.src.includes(".m3u8")) {
					urls.add(source.src);
				}
			});
		});

		// 2. Check all <source> tags
		document.querySelectorAll("source").forEach((source) => {
			if (source.src && source.src.includes(".m3u8")) {
				urls.add(source.src);
			}
		});

		// 3. Search entire page HTML for m3u8 URLs
		const pageHTML = document.documentElement.outerHTML;
		const m3u8Regex = /(https?:\/\/[^\s"'<>]+\.m3u8[^\s"'<>]*)/gi;
		const matches = pageHTML.match(m3u8Regex);
		if (matches) {
			matches.forEach((url) => urls.add(url));
		}

		return Array.from(urls);
	}

	// Copy to clipboard
	function copyToClipboard(text) {
		if (navigator.clipboard && navigator.clipboard.writeText) {
			navigator.clipboard
				.writeText(text)
				.then(() => {
					return true;
				})
				.catch(() => {
					return fallbackCopy(text);
				});
		} else {
			return fallbackCopy(text);
		}
	}

	function fallbackCopy(text) {
		const textarea = document.createElement("textarea");
		textarea.value = text;
		textarea.style.position = "fixed";
		textarea.style.opacity = "0";
		document.body.appendChild(textarea);
		textarea.select();
		try {
			document.execCommand("copy");
			document.body.removeChild(textarea);
			return true;
		} catch {
			document.body.removeChild(textarea);
			return false;
		}
	}

	// Main execution
	const urls = findM3U8URLs();

	if (urls.length === 0) {
		alert(
			"❌ No m3u8 URLs found on this page.\n\nTip: Make sure the video player has loaded before clicking this bookmarklet."
		);
		return;
	}

	if (urls.length === 1) {
		copyToClipboard(urls[0]);
		alert(
			'✅ M3U8 URL copied to clipboard!\n\nNow run in Terminal:\n\npython3 transito.py "' +
				urls[0] +
				'" -o video.mp4'
		);
	} else {
		// Multiple URLs found - show selection
		const list = urls.map((url, i) => `${i + 1}. ${url}`).join("\n\n");
		const choice = prompt(
			"Multiple m3u8 URLs found:\n\n" +
				list +
				"\n\nEnter number to copy (1-" +
				urls.length +
				"):"
		);
		if (choice) {
			const index = parseInt(choice) - 1;
			if (index >= 0 && index < urls.length) {
				copyToClipboard(urls[index]);
				alert("✅ M3U8 URL copied!\n\n" + urls[index]);
			}
		}
	}
})();
