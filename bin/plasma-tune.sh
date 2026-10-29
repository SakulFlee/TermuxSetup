#!/data/data/com.termux/files/usr/bin/bash
# Apply the tablet-friendly Plasma defaults. Run after Plasma is running.
set -u

[ -f "$HOME/.config/tablet-session" ] && . "$HOME/.config/tablet-session"
: "${DISPLAY:=:0}"
export DISPLAY

[ -f "$HOME/.cache/tablet-dbus.env" ] && . "$HOME/.cache/tablet-dbus.env"

# Touch-friendly defaults.
kwriteconfig6 --file kdeglobals --group KDE --key SingleClick true 2>/dev/null || true
kwriteconfig6 --file kdeglobals --group KDE --key TabletMode always 2>/dev/null || true

# 80 px panel (the default Plasma panel is too thin for a tablet).
kwriteconfig6 --file plasma-org.kde.plasma.desktop-appletsrc \
  --group Containments --group 2 --key thickness 80 2>/dev/null || true

# Apply the height immediately, without restarting plasmashell.
if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.plasmashell /PlasmaShell \
    org.kde.PlasmaShell.evaluateScript 'panels()[0].height = 80' >/dev/null 2>&1 || true
fi
