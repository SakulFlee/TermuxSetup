#!/data/data/com.termux/files/usr/bin/bash
# Open the Syncthing web UI.
#
# Syncthing detects an already-running instance for the same home directory and
# opens the GUI instead of starting a second daemon. If no instance is running,
# it starts one and then opens the GUI.
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

SYNC_HOME="$HOME/.local/state/syncthing"
GUI_ADDRESS="${SYNCTHING_GUI_ADDRESS:-127.0.0.1:8384}"

exec syncthing --home "$SYNC_HOME" --gui-address="$GUI_ADDRESS" "$@"
