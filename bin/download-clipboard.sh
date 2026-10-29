#!/data/data/com.termux/files/usr/bin/bash
# Download a URL from the clipboard (or first argument) with yt-dlp.
set -u

BIN="$HOME/.local/bin"
if [ -d "$HOME/storage/downloads" ]; then
  OUT="${YTDLP_OUT:-$HOME/storage/downloads/ytdlp}"
else
  OUT="${YTDLP_OUT:-$HOME/Downloads}"
fi
LOG="$HOME/ytdlp.log"

command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock || true

url="${1:-}"
if [ -z "$url" ]; then
  url="$(termux-clipboard-get 2>/dev/null || true)"
fi

if [ -z "$url" ] && command -v termux-dialog >/dev/null 2>&1; then
  data="$(termux-dialog -t "Download URL" -i "https://" 2>/dev/null || true)"
  url="$(printf '%s' "$data" | jq -r '.text // empty' 2>/dev/null || true)"
fi

if [ -z "$url" ]; then
  command -v termux-toast >/dev/null 2>&1 && termux-toast "No URL in clipboard" || true
  exit 1
fi

command -v termux-toast >/dev/null 2>&1 && termux-toast "Starting download..." || true
command -v termux-notification >/dev/null 2>&1 && \
  termux-notification --id ytdlp --title "yt-dlp" --content "Downloading: $url" --ongoing || true

if "$BIN/ytdl" "$url" >>"$LOG" 2>&1; then
  command -v termux-notification >/dev/null 2>&1 && \
    termux-notification --id ytdlp --title "yt-dlp" --content "Download finished" \
      --button1 "Open folder" --button1-action "termux-open $OUT" || true
else
  command -v termux-notification >/dev/null 2>&1 && \
    termux-notification --id ytdlp --title "yt-dlp" --content "Download failed - see ~/ytdlp.log" || true
fi

# Release the wake-lock only if no desktop session is holding it.
if ! pgrep -x plasmashell >/dev/null 2>&1 && ! pgrep -x openbox >/dev/null 2>&1; then
  command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock || true
fi
