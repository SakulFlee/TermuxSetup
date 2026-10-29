#!/data/data/com.termux/files/usr/bin/bash
# Bring Termux:X11 to the foreground, starting the desktop if necessary.
set -u

"$HOME/.local/bin/start-desktop.sh" >/dev/null 2>&1 || true

am start --user 0 --windowingMode 1 \
  -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || \
am start --user 0 \
  -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
