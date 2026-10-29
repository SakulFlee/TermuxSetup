#!/data/data/com.termux/files/usr/bin/bash
# Ask for a URL with a native Android dialog and download it with yt-dlp.
set -u

BIN="$HOME/.local/bin"

clip="$(termux-clipboard-get 2>/dev/null || true)"
data="$(termux-dialog -t "yt-dlp download" -i "${clip:-https://}" 2>/dev/null || true)"
url="$(printf '%s' "$data" | jq -r '.text // empty' 2>/dev/null || true)"

[ -z "$url" ] && exit 0
exec "$BIN/download-clipboard.sh" "$url"
