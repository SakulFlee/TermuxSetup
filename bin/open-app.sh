#!/data/data/com.termux/files/usr/bin/bash
# Start the desktop if needed, then open (or focus) one app.
set -u

APP="${1:-firefox}"
BIN="$HOME/.local/bin"

[ -f "$HOME/.config/tablet-session" ] && . "$HOME/.config/tablet-session"
: "${DISPLAY:=:0}"

"$BIN/start-desktop.sh" >/dev/null 2>&1 || true
[ -f "$HOME/.cache/tablet-dbus.env" ] && . "$HOME/.cache/tablet-dbus.env"
export DISPLAY

maximize_app() {
  local pattern id
  for pattern in "$@"; do
    for _ in 1 2 3 4 5 6; do
      id="$(xdotool search --class "$pattern" 2>/dev/null | head -1 || true)"
      if [ -n "$id" ]; then
        wmctrl -i -r "$id" -b add,maximized_vert,maximized_horz >/dev/null 2>&1 || true
        return 0
      fi
      sleep 0.5
    done
  done
}

case "$APP" in
  firefox)
    if ! pgrep -x firefox >/dev/null 2>&1; then
      setsid "$BIN/firefox-tablet" </dev/null >/dev/null 2>&1 &
      sleep 1
    fi
    maximize_app Firefox firefox
    ;;
  terminal)
    if ! pgrep -x qterminal >/dev/null 2>&1; then
      setsid qterminal </dev/null >/dev/null 2>&1 &
      sleep 1
    fi
    maximize_app qterminal
    ;;
  files)
    if ! pgrep -x pcmanfm >/dev/null 2>&1; then
      setsid pcmanfm "$HOME/storage/shared" </dev/null >/dev/null 2>&1 &
      sleep 1
    fi
    maximize_app Pcmanfm pcmanfm
    ;;
  apps)
    setsid rofi -show drun -show-icons -theme "$HOME/.config/rofi/tablet.rasi" \
      </dev/null >/dev/null 2>&1 &
    ;;
  audio)
    pgrep -x pavucontrol >/dev/null 2>&1 || \
      setsid pavucontrol </dev/null >/dev/null 2>&1 &
    ;;
  settings)
    pgrep -x lxappearance >/dev/null 2>&1 || \
      setsid lxappearance </dev/null >/dev/null 2>&1 &
    ;;
  obconf)
    pgrep -x obconf-qt >/dev/null 2>&1 || \
      setsid obconf-qt </dev/null >/dev/null 2>&1 &
    ;;
  *)
    echo "Unknown app: $APP" >&2
    exit 1
    ;;
esac

am start --user 0 --windowingMode 1 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || \
  am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
