#!/data/data/com.termux/files/usr/bin/sh
# Termux:Boot — start the always-on services.
export PATH=/data/data/com.termux/files/usr/bin:$PATH
export SVDIR=/data/data/com.termux/files/usr/var/service

# No permanent wake-lock: it costs battery. The desktop, yt-dlp and sync
# scripts take a wake-lock only while they are actually doing work.
if ! pgrep -x runsvdir >/dev/null 2>&1; then
  setsid runsvdir "$SVDIR" </dev/null >/dev/null 2>&1 &
  sleep 1
fi
sv up tablet-sshd >/dev/null 2>&1 || true

# Syncthing is on-demand (manual "Sync Now" or the daily job).
touch "$SVDIR/tablet-syncthing/down"
sv down tablet-syncthing >/dev/null 2>&1 || true
