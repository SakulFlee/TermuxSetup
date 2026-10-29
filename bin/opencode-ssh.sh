#!/data/data/com.termux/files/usr/bin/bash
# Run OpenCode on Dendra over SSH.
set -u

[ -f "$HOME/.config/tablet-session" ] && . "$HOME/.config/tablet-session"
: "${OPENCODE_HOST:=sakulflee@192.168.178.109}"

exec ssh -t -o ServerAliveInterval=30 -o StrictHostKeyChecking=accept-new \
  "$OPENCODE_HOST" 'cd ~ && exec opencode'
