#!/data/data/com.termux/files/usr/bin/bash
# Stop the X11 session and its helper processes.
set -u

[ -f "$HOME/.config/tablet-session" ] && . "$HOME/.config/tablet-session"
: "${DISPLAY:=:0}"

pkill -x xfce4-session 2>/dev/null || true
pkill -x plasmashell 2>/dev/null || true
pkill -x kwin_x11 2>/dev/null || true
pkill -f "openbox-session" 2>/dev/null || true
pkill -x openbox 2>/dev/null || true
pkill -x tint2 2>/dev/null || true
pkill -x devilspie2 2>/dev/null || true
pkill -x matchbox-keyboard 2>/dev/null || true
pkill -x xvkbd 2>/dev/null || true
pkill -x firefox 2>/dev/null || true
pkill -f "termux-x11 .*${DISPLAY}" 2>/dev/null || true

am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1 || true

if [ -f "$HOME/.cache/tablet-dbus.env" ]; then
  . "$HOME/.cache/tablet-dbus.env"
  [ -n "${DBUS_SESSION_BUS_PID:-}" ] && kill "$DBUS_SESSION_BUS_PID" 2>/dev/null || true
  rm -f "$HOME/.cache/tablet-dbus.env"
fi

command -v termux-wake-unlock >/dev/null 2>&1 && termux-wake-unlock || true
