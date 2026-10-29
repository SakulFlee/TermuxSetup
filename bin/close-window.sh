#!/data/data/com.termux/files/usr/bin/bash
set -u
[ -f "$HOME/.config/tablet-session" ] && . "$HOME/.config/tablet-session"
: "${DISPLAY:=:0}"
export DISPLAY
wmctrl -c :ACTIVE:
