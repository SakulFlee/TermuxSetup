#!/data/data/com.termux/files/usr/bin/bash
# Set Termux:X11 orientation: auto, landscape or portrait.
set -u

case "${1:-auto}" in
  auto|landscape|portrait)
    exec termux-x11-preference "forceOrientation:$1"
    ;;
  *)
    echo "usage: $0 {auto|landscape|portrait}" >&2
    exit 1
    ;;
esac
