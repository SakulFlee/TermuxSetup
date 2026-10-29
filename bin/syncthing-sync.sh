#!/data/data/com.termux/files/usr/bin/bash
# Start Syncthing on demand, sync the personal folder, then stop it again.
#
# Usage:
#   syncthing-sync.sh              incremental run (10 minute timeout)
#   syncthing-sync.sh --initial    initial run (no timeout, use on charger)
set -u

: "${HOME:=/data/data/com.termux/files/home}"
: "${PREFIX:=/data/data/com.termux/files/usr}"
export HOME PREFIX
export PATH="$PREFIX/bin:$HOME/.local/bin:$PATH"

SVDIR="$PREFIX/var/service"
export SVDIR
SYNC_HOME="$HOME/.local/state/syncthing"
FOLDER="/sdcard/Personal"
API="http://127.0.0.1:8384"
LOG="$HOME/syncthing-sync.log"
LOCK="$HOME/.cache/syncthing-sync.lock"

MODE="${1:-incremental}"
TIMEOUT=600
[ "$MODE" = "--initial" ] && TIMEOUT=0

mkdir -p "$HOME/.cache" "$FOLDER"
exec 9>"$LOCK"
if ! flock -n 9; then
  termux-toast "Syncthing sync already running" 2>/dev/null || true
  exit 0
fi

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >>"$LOG"; }
notify() { termux-notification --id syncthing --title "Syncthing" --content "$1" 2>/dev/null || true; }

log "start ($MODE)"
termux-wake-lock >/dev/null 2>&1 || true

free_kb=$(df -Pk /sdcard | awk 'NR==2 {print $4}')
min_kb=$((70 * 1024 * 1024))
if [ -z "$free_kb" ] || [ "$free_kb" -lt "$min_kb" ]; then
  msg="Not enough free space ($(( ${free_kb:-0} / 1024 / 1024 )) GB free; need ~70 GB)"
  log "$msg"
  notify "$msg"
  exit 1
fi

# Syncthing wants its marker; re-create it after a manual wipe.
mkdir -p "$FOLDER/.stfolder"

if ! pgrep -x runsvdir >/dev/null 2>&1; then
  setsid runsvdir "$SVDIR" </dev/null >/dev/null 2>&1 &
  sleep 1
fi

rm -f "$SVDIR/tablet-syncthing/down"
sv up tablet-syncthing >>"$LOG" 2>&1 || true

key=$(sed -n 's:.*<apikey>\([^<]*\)</apikey>.*:\1:p' "$SYNC_HOME/config.xml" | head -1)
if [ -z "$key" ]; then
  log "no API key in config"
  notify "Syncthing config missing"
  exit 1
fi

for _ in $(seq 1 60); do
  curl -sf -H "X-API-Key: $key" "$API/rest/system/status" >/dev/null 2>&1 && break
  sleep 1
done

# The folder type is configured separately (currently receive-only). Do not
# overwrite it here, so switching to sendreceive later is not undone by the job.
curl -s -X PATCH -H "X-API-Key: $key" -H 'Content-Type: application/json' \
  -d '{"paused":false}' \
  "$API/rest/config/folders/personal" >>"$LOG" 2>&1 || log "PATCH unpause failed"

# Give the remote index a moment to arrive. A freshly wiped folder starts with
# globalFiles=0/needBytes=0, which must NOT be mistaken for "already in sync".
sleep 5

start=$(date +%s)
result="timeout"
while :; do
  status=$(curl -s -H "X-API-Key: $key" "$API/rest/db/status?folder=personal")
  state=$(printf '%s' "$status" | jq -r '.state // "unknown"' 2>/dev/null)
  need=$(printf '%s' "$status" | jq -r '.needBytes // 0' 2>/dev/null)
  global=$(printf '%s' "$status" | jq -r '.globalFiles // 0' 2>/dev/null)
  in_sync=$(printf '%s' "$status" | jq -r '.inSyncFiles // 0' 2>/dev/null)
  errors=$(printf '%s' "$status" | jq -r '.errors // 0' 2>/dev/null)

  [ "${errors:-0}" -gt 0 ] && log "folder errors: $errors"

  if [ "$state" = "idle" ] && [ "${need:-0}" -eq 0 ] \
     && [ "${global:-0}" -gt 0 ] && [ "${in_sync:-0}" -ge "${global:-0}" ]; then
    result="ok"
    break
  fi

  if [ "$TIMEOUT" -gt 0 ] && [ $(( $(date +%s) - start )) -ge "$TIMEOUT" ]; then
    result="timeout"
    break
  fi
  sleep 10
done

curl -s -X PATCH -H "X-API-Key: $key" -H 'Content-Type: application/json' \
  -d '{"paused":true}' \
  "$API/rest/config/folders/personal" >>"$LOG" 2>&1 || true

sv -w 10 down tablet-syncthing >>"$LOG" 2>&1 || true
touch "$SVDIR/tablet-syncthing/down"

if [ "$result" = "ok" ]; then
  notify "Sync finished"
else
  notify "Sync paused after timeout; it will resume on the next run"
fi
log "end ($result)"

if ! pgrep -x plasmashell >/dev/null 2>&1 && ! pgrep -x openbox >/dev/null 2>&1; then
  termux-wake-unlock >/dev/null 2>&1 || true
fi
