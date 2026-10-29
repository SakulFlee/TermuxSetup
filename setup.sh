#!/data/data/com.termux/files/usr/bin/bash
# One-shot Termux tablet setup.
#
# Run this from the Termux app, from the repository root:
#
#   bash setup.sh
#
# The base Termux APK cannot be installed by this script because the script
# runs inside Termux. The other Termux plugins are downloaded, checksum
# verified and opened with Android's package installer; Android still requires
# a tap for each installation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APK_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/termux-setup/apks"
APK_DIR=""
SKIP_PACKAGES=0
NO_APKS=0
FORCE_APKS=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: bash setup.sh [options]

Options:
  --skip-packages   Do not install/update Termux packages.
  --no-apks         Do not download or install Android APKs.
  --apk-dir DIR     Use APKs from DIR instead of downloading them.
  --force-apks      Open already-installed APKs again (base Termux excluded).
  --yes             Do not pause for confirmation before provisioning.
  -h, --help        Show this help.
EOF
}

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die()  { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-packages) SKIP_PACKAGES=1 ;;
    --no-apks)       NO_APKS=1 ;;
    --apk-dir)       [ "$#" -ge 2 ] || die "--apk-dir needs a directory"; APK_DIR="$2"; shift ;;
    --force-apks)    FORCE_APKS=1 ;;
    --yes)           ASSUME_YES=1 ;;
    -h|--help)       usage; exit 0 ;;
    *)               die "Unknown option: $1 (try --help)" ;;
  esac
  shift
done

[ -n "${PREFIX:-}" ] && [ -d "$PREFIX" ] || die "Run this inside the Termux app."
have pkg || die "Termux pkg is not available."
have pm || die "Android pm is not available."
[ "$(uname -m)" = "aarch64" ] || warn "This setup is tested on arm64/aarch64 only."

if [ ! -f "$ROOT/config.env" ]; then
  cp "$ROOT/config.example" "$ROOT/config.env"
  echo "Created $ROOT/config.env from config.example."
  echo "Review it if this is not Dendra's tablet; setup continues with the defaults."
fi

# Local, non-committed settings.
# shellcheck disable=SC1091
. "$ROOT/config.env"
: "${SESSION:=plasma}"
: "${DISPLAY:=:0}"
: "${DPI:=144}"
: "${OPENCODE_HOST:=sakulflee@192.168.178.109}"
: "${SYNCTHING_FOLDER:=/sdcard/Personal}"
: "${SYNCTHING_FOLDER_ID:=personal}"
export SESSION DISPLAY DPI OPENCODE_HOST SYNCTHING_FOLDER SYNCTHING_FOLDER_ID

if [ "$SKIP_PACKAGES" -eq 0 ]; then
  log "Updating package lists"
  pkg update -y

  log "Installing the x11 repository"
  pkg install -y x11-repo

  mapfile -t packages < <(grep -vE '^[[:space:]]*(#|$)' "$ROOT/packages.txt")
  log "Installing ${#packages[@]} Termux packages"
  pkg install -y "${packages[@]}"
else
  log "Skipping package installation (--skip-packages)"
fi

sig_of() {
  dumpsys package "$1" 2>/dev/null |
    sed -n 's/.*signatures:\[\([^]]*\)\].*/\1/p' |
    head -1
}

pkg_installed() {
  pm list packages 2>/dev/null | grep -qx "package:$1"
}

wait_for_package() {
  local pkg="$1" i
  for i in $(seq 1 180); do
    pkg_installed "$pkg" && return 0
    sleep 1
  done
  return 1
}

install_apk() {
  local pkg="$1" file="$2" sha="$3" apk="$4"
  local cached="$APK_CACHE/$file"

  if [ -n "$APK_DIR" ]; then
    [ -f "$APK_DIR/$file" ] || die "APK not found: $APK_DIR/$file"
    apk="$APK_DIR/$file"
  else
    mkdir -p "$APK_CACHE"
    if [ ! -f "$cached" ] || ! echo "$sha  $cached" | sha256sum -c - >/dev/null 2>&1; then
      log "Downloading $file"
      curl -L --fail --retry 3 --silent --show-error -o "$cached" "$apk"
    fi
    apk="$cached"
  fi

  if ! echo "$sha  $apk" | sha256sum -c - >/dev/null 2>&1; then
    die "Checksum mismatch for $file. The upstream or the file changed."
  fi

  log "Installing $pkg"
  echo "Android will ask you to install $file; tap Install."
  termux-open "$apk"
  if ! wait_for_package "$pkg"; then
    die "$pkg was not installed. If Android reported a signature conflict,
         uninstall the old plugin and rerun setup with the GitHub debug APK."
  fi
  log "$pkg installed"
}

if [ "$NO_APKS" -eq 0 ]; then
  have termux-open || die "termux-open is missing; install termux-tools first."
  while IFS=$'\t' read -r pkg version file url sha; do
    case "$pkg" in ''|'#'*) continue ;; esac
    if pkg_installed "$pkg" && { [ "$pkg" = "com.termux" ] || [ "$FORCE_APKS" -eq 0 ]; }; then
      log "$pkg already installed; skipping"
      continue
    fi
    install_apk "$pkg" "$file" "$sha" "$url"
    if [ "$pkg" = "com.termux" ]; then
      warn "If Termux was updated, close and reopen Termux after setup."
    fi
  done < "$ROOT/apks.tsv"

  log "Checking APK signing compatibility"
  base_sig="$(sig_of com.termux)"
  [ -n "$base_sig" ] || warn "Could not read com.termux signature; skipping signature check."
  while IFS=$'\t' read -r pkg version file url sha; do
    case "$pkg" in ''|'#'*|com.termux) continue ;; esac
    pkg_installed "$pkg" || die "$pkg is not installed."
    sig="$(sig_of "$pkg")"
    if [ -n "$base_sig" ] && [ "$sig" != "$base_sig" ]; then
      die "$pkg has a different signing key than com.termux."
    fi
  done < "$ROOT/apks.tsv"
  if ! dumpsys package com.termux.x11 2>/dev/null | grep -q 'sharedUser=.*com.termux/'; then
    die "Termux:X11 is not using Termux's shared UID. Install the sharedUid APK."
  fi
else
  log "Skipping APK installation (--no-apks)"
fi

log "Installing scripts and desktop configuration"
( cd "$ROOT" && bash ./install.sh )

log "Provisioning Termux storage and services"
if [ "$ASSUME_YES" -eq 0 ]; then
  echo
  echo "Android will now ask for storage access. Grant it, then press Enter."
  read -r _
fi
( cd "$ROOT" && bash ./provision.sh )

log "Setup complete"
cat <<EOF

Manual Android steps that cannot be automated from Termux:
  1. Termux:API -> Special app access -> Modify system settings -> Allow
     (needed for Plasma's brightness control)
  2. Termux -> Display over other apps -> Allow
  3. Termux -> Battery -> Unrestricted
  4. Start the desktop:  ~/.local/bin/start-desktop.sh

Other useful checks:
  - Termux:X11: displayStretch=false, forceOrientation=auto
  - Firefox: log in to the sites you need; ytdl reads the tablet profile
  - Syncthing: print the device ID and add it to the peer, then run:
      ~/.local/bin/syncthing-sync.sh --initial
  - Review $ROOT/config.env for any device-specific values.
EOF
