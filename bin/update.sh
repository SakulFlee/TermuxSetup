#!/data/data/com.termux/files/usr/bin/bash
# Pull the TermuxSetup repository and reinstall the managed files.
set -euo pipefail

[ -f "$HOME/.config/tablet-session" ] && . "$HOME/.config/tablet-session"

REPO="${TERMUX_SETUP_DIR:-$HOME/TermuxSetup}"

if [ ! -d "$REPO/.git" ]; then
  echo "TermuxSetup repository not found: $REPO" >&2
  echo "Clone it with:" >&2
  echo "  git clone https://forgejo.sakul-flee.de/SakulFlee/TermuxSetup \"$REPO\"" >&2
  exit 1
fi

echo "Updating $REPO"
git -C "$REPO" pull --ff-only

echo "Installing updated files"
exec bash "$REPO/install.sh"
