#!/data/data/com.termux/files/usr/bin/bash
# One-time first-run provisioning. MUST be run from the Termux app (or an
# SSH session started by the Termux app), not via `run-as`, because only the
# app's SELinux context may access /sdcard.
set -uo pipefail

export PATH="$PREFIX/bin:$HOME/.local/bin:$PATH"
export SVDIR="$PREFIX/var/service"

echo "== storage =="
termux-setup-storage || true
mkdir -p "$HOME/storage/downloads/ytdlp" 2>/dev/null || true

echo "== termux settings =="
termux-reload-settings >/dev/null 2>&1 || true

echo "== service supervisor =="
if ! pgrep -x runsvdir >/dev/null 2>&1; then
  nohup runsvdir "$SVDIR" >/dev/null 2>&1 &
  sleep 1
fi

echo "== services =="
rm -f "$SVDIR/tablet-sshd/down"
sv up tablet-sshd || true
# Syncthing is on-demand: manual "Sync Now" or the daily scheduler job.
touch "$SVDIR/tablet-syncthing/down"
sv down tablet-syncthing >/dev/null 2>&1 || true
sleep 1
sv status tablet-sshd || true
sv status tablet-syncthing || true

echo "provision: ok"
echo "sshd: $(pgrep -f 'sshd.*sshd_config' | head -1 || true)"
echo "syncthing: $(pgrep -x syncthing | head -1 || true)"
