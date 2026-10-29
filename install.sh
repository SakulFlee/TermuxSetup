#!/data/data/com.termux/files/usr/bin/bash
# Install the tablet shell files into the Termux home directory.
# This script does not start services or the desktop.
set -euo pipefail

: "${PREFIX:=/data/data/com.termux/files/usr}"
SRC="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
CFG="$HOME/.config"
STAMP="$(date +%Y%m%d-%H%M%S)"
AUTHORIZED_KEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIImnWUykSX10iZYDF4g0bqy/uOXppRwWodtmg3iYBfBS sakulflee@nixos'

mkdir -p "$BIN" "$APPS" "$CFG/openbox" "$CFG/tint2" "$CFG/rofi" "$CFG/devilspie2" \
  "$CFG/gtk-3.0" "$CFG/gtk-4.0" "$CFG/dunst" "$CFG/qterminal.org" \
  "$HOME/.shortcuts" "$HOME/.termux/boot" "$HOME/.local/state" "$HOME/.cache" \
  "$HOME/.mozilla/firefox/tablet/chrome" "$HOME/.ssh"

backup() {
  [ -e "$1" ] && cp -a "$1" "$1.bak-$STAMP" || true
}

put() {
  local src="$1" dst="$2" mode="$3"
  backup "$dst"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  chmod "$mode" "$dst"
}

for f in start-desktop.sh stop-desktop.sh open-app.sh firefox-tablet \
         download-clipboard.sh download-url.sh opencode-ssh.sh toggle-keyboard.sh \
         close-window.sh show-desktop.sh set-orientation.sh syncthing-sync.sh \
         plasma-tune.sh; do
  put "$SRC/bin/$f" "$BIN/$f" 755
done
put "$SRC/bin/ytdl" "$BIN/ytdl" 755

put "$SRC/openbox/rc.xml"              "$CFG/openbox/rc.xml" 644
put "$SRC/openbox/autostart"           "$CFG/openbox/autostart" 755
put "$SRC/openbox/menu.xml"            "$CFG/openbox/menu.xml" 644
put "$SRC/tint2/tint2rc"               "$CFG/tint2/tint2rc" 644
put "$SRC/rofi/tablet.rasi"            "$CFG/rofi/tablet.rasi" 644
put "$SRC/devilspie2/maximize.lua"     "$CFG/devilspie2/maximize.lua" 644
put "$SRC/Xresources"                  "$HOME/.Xresources" 644
put "$SRC/gtk-3.0/settings.ini"        "$CFG/gtk-3.0/settings.ini" 644
put "$SRC/gtk-4.0/settings.ini"        "$CFG/gtk-4.0/settings.ini" 644
put "$SRC/dunst/dunstrc"               "$CFG/dunst/dunstrc" 644
put "$SRC/qterminal/qterminal.ini"     "$CFG/qterminal.org/qterminal.ini" 644
put "$SRC/session/tablet-session"      "$CFG/tablet-session" 644
put "$SRC/ssh/sshd_config"             "$HOME/.ssh/sshd_config" 600
put "$SRC/termux.properties"           "$HOME/.termux/termux.properties" 600
put "$SRC/firefox/user.js"             "$HOME/.mozilla/firefox/tablet/user.js" 644
put "$SRC/firefox/userChrome.css"      "$HOME/.mozilla/firefox/tablet/chrome/userChrome.css" 644

for f in "$SRC"/desktop/*.desktop; do
  put "$f" "$APPS/$(basename "$f")" 644
done

# SSH access for Dendra.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
grep -qF "$AUTHORIZED_KEY" "$HOME/.ssh/authorized_keys" 2>/dev/null || \
  printf '%s\n' "$AUTHORIZED_KEY" >> "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"
ssh-keygen -A >/dev/null 2>&1 || true

# Termux:Widget shortcuts.
make_shortcut() {
  local name="$1" script="$2" arg="${3:-}"
  local file="$HOME/.shortcuts/$name"
  {
    echo '#!/data/data/com.termux/files/usr/bin/bash'
    printf 'exec "$HOME/.local/bin/%s"' "$script"
    [ -n "$arg" ] && printf ' %q' "$arg"
    echo
  } > "$file"
  chmod 700 "$file"
}

# Older installs kept backups in ~/.shortcuts, where Termux:Widget would list
# them as duplicate shortcuts.
find "$HOME/.shortcuts" -maxdepth 1 -name '*.bak-*' -delete 2>/dev/null || true
chmod 700 "$HOME/.shortcuts" "$HOME/.termux" 2>/dev/null || true

make_shortcut "Start Desktop"       start-desktop.sh
make_shortcut "Stop Desktop"        stop-desktop.sh
make_shortcut "Firefox"             open-app.sh firefox
make_shortcut "Terminal"            open-app.sh terminal
make_shortcut "Files"               open-app.sh files
make_shortcut "Download Clipboard"  download-clipboard.sh
make_shortcut "Download URL"        download-url.sh
make_shortcut "OpenCode"            opencode-ssh.sh
make_shortcut "Show Desktop"        show-desktop.sh
make_shortcut "Sync Now"            syncthing-sync.sh

# Make ~/.local/bin available in interactive shells.
MARK="# tablet-shell PATH"
if ! grep -qF "$MARK" "$HOME/.bashrc" 2>/dev/null; then
  printf '\n%s\nexport PATH="$HOME/.local/bin:$PATH"\n' "$MARK" >> "$HOME/.bashrc"
fi

# runit services. The "down" files keep them stopped until provision.sh runs
# in the Termux app context (where /sdcard access is available).
SVDIR="$PREFIX/var/service"
mkdir -p "$SVDIR/tablet-sshd" "$SVDIR/tablet-syncthing"
put "$SRC/service/tablet-sshd.run" "$SVDIR/tablet-sshd/run" 755
put "$SRC/service/tablet-syncthing.run" "$SVDIR/tablet-syncthing/run" 755
# SSH is always on. Syncthing is started on demand by syncthing-sync.sh
# (manual "Sync Now" or the daily termux-job-scheduler job), so keep it down.
touch "$SVDIR/tablet-syncthing/down"

put "$SRC/boot/start-services.sh" "$HOME/.termux/boot/start-services.sh" 700
put "$SRC/provision.sh" "$BIN/provision.sh" 755

echo "Installed tablet shell into $HOME"
echo "Next: run provision.sh from the Termux app (not via run-as)."
echo
echo "Termux:API needs 'Modify system settings' for Plasma brightness."
echo "From a computer with adb: appops set com.termux.api WRITE_SETTINGS allow"
echo "Or: Settings -> Apps -> Termux:API -> Special app access -> Modify system settings."
