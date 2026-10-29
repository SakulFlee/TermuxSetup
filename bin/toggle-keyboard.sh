#!/data/data/com.termux/files/usr/bin/bash
# Toggle an on-screen X11 keyboard. Termux:X11's Back button is the primary
# keyboard toggle; this is a fallback for hardware-keyboard-less use.
set -u

[ -f "$HOME/.config/tablet-session" ] && . "$HOME/.config/tablet-session"
: "${DISPLAY:=:0}"
export DISPLAY

if pgrep -x xvkbd >/dev/null 2>&1; then
  pkill -x xvkbd
elif pgrep -x matchbox-keyboard >/dev/null 2>&1; then
  pkill -x matchbox-keyboard
else
  # xvkbd scales better on a 1600x2560 display than matchbox-keyboard.
  nohup xvkbd -geometry 1500x420+0-80 -font "DejaVu Sans 12" >/dev/null 2>&1 &
fi
