#!/data/data/com.termux/files/usr/bin/bash
# Open the Syncthing web UI, starting Syncthing and a sync if necessary.
#
# Syncthing detects an already-running instance for the same home directory and
# opens the GUI instead of starting a second daemon. If no instance is running,
# this starts the runit service, resumes the configured folder, and then lets
# Syncthing open the GUI.
set -u

: "${HOME:=/data/data/com.termux/files/home}"
: "${PREFIX:=/data/data/com.termux/files/usr}"
export HOME PREFIX
export PATH="$PREFIX/bin:$HOME/.local/bin:$PATH"

# Optional per-device settings written by install.sh.
if [ -f "$HOME/.config/tablet-session" ]; then
  # shellcheck disable=SC1091
  . "$HOME/.config/tablet-session"
fi

SVDIR="${SVDIR:-$PREFIX/var/service}"
SYNC_HOME="$HOME/.local/state/syncthing"
GUI_ADDRESS="${SYNCTHING_GUI_ADDRESS:-127.0.0.1:8384}"
FOLDER_ID="${SYNCTHING_FOLDER_ID:-personal}"
API="http://$GUI_ADDRESS"
key=$(sed -n 's:.*<apikey>\([^<]*\)</apikey>.*:\1:p' "$SYNC_HOME/config.xml" 2>/dev/null | head -1)

api_up() {
  [ -n "$key" ] && curl -sf -m 2 -H "X-API-Key: $key" \
    "$API/rest/system/status" >/dev/null 2>&1
}

started=0
if ! pidof syncthing >/dev/null 2>&1; then
  started=1
  rm -f "$SVDIR/tablet-syncthing/down"
  sv up tablet-syncthing >/dev/null 2>&1 || true
  # Wait for the API only when the daemon was just started, so the folder can
  # be resumed. The UI itself does not depend on this wait.
  for _ in $(seq 1 30); do
    api_up && break
    sleep 1
  done
fi

# A previous timed sync leaves the folder paused. Resume it when this shortcut
# is what started the daemon, so tapping the widget also starts a sync.
if [ "$started" -eq 1 ] && api_up; then
  curl -s -m 5 -X PATCH -H "X-API-Key: $key" \
    -H 'Content-Type: application/json' -d '{"paused":false}' \
    "$API/rest/config/folders/$FOLDER_ID" >/dev/null 2>&1 || true
fi

exec syncthing --home "$SYNC_HOME" --gui-address="$GUI_ADDRESS" "$@"
