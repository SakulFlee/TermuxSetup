#!/data/data/com.termux/files/usr/bin/bash
# Start (or re-focus) the tablet X11 session.
set -u

SESSION_FILE="$HOME/.config/tablet-session"
[ -f "$SESSION_FILE" ] && . "$SESSION_FILE"

: "${SESSION:=openbox}"
: "${DISPLAY:=:0}"
: "${DPI:=200}"
: "${OPENCODE_HOST:=sakulflee@192.168.178.109}"

RUNTIME_DIR="$HOME/.cache/xdg-runtime"
DBUS_ENV="$HOME/.cache/tablet-dbus.env"
X11_LOG="$HOME/.local/state/tablet-x11.log"

mkdir -p "$HOME/.local/state" "$HOME/.cache" "$RUNTIME_DIR"
chmod 700 "$RUNTIME_DIR"
export XDG_RUNTIME_DIR="$RUNTIME_DIR"

# Keep the CPU awake while the desktop is open.
command -v termux-wake-lock >/dev/null 2>&1 && termux-wake-lock || true

# Audio: Termux's default.pa loads module-sles-sink.
if ! pgrep -x pulseaudio >/dev/null 2>&1; then
  pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1 || true
fi

# Shared session bus, so apps started later from a widget still get the bus.
if [ -f "$DBUS_ENV" ]; then
  . "$DBUS_ENV"
fi
if [ -z "${DBUS_SESSION_BUS_PID:-}" ] || ! kill -0 "$DBUS_SESSION_BUS_PID" 2>/dev/null; then
  eval "$(dbus-launch --sh-syntax)"
  {
    printf 'export DBUS_SESSION_BUS_ADDRESS=%q\n' "$DBUS_SESSION_BUS_ADDRESS"
    printf 'export DBUS_SESSION_BUS_PID=%q\n' "$DBUS_SESSION_BUS_PID"
  } > "$DBUS_ENV"
fi

export DISPLAY

if ! pgrep -f "termux-x11 .*${DISPLAY}" >/dev/null 2>&1; then
  case "$SESSION" in
    plasma)
      export XDG_SESSION_TYPE=x11
      export XDG_SESSION_DESKTOP=KDE
      export XDG_CURRENT_DESKTOP=KDE
      export KDE_FULL_SESSION=true
      export KDE_SESSION_VERSION=6
      export QT_QPA_PLATFORM=xcb
      export QT_AUTO_SCREEN_SCALE_FACTOR=1
      export GDK_SCALE=1
      export XCURSOR_SIZE=32
      # Software-friendly compositor on Termux:X11.
      export KWIN_COMPOSE=N
      xstartup="startplasma-x11"
      ;;
    *)
      xstartup="openbox-session"
      ;;
  esac

  setsid termux-x11 "$DISPLAY" -dpi "$DPI" -xstartup "$xstartup" </dev/null >"$X11_LOG" 2>&1 &
  sleep 2
fi

# Wait until the X server accepts clients.
for _ in $(seq 1 40); do
  xdpyinfo >/dev/null 2>&1 && break
  sleep 0.5
done

# If the X server was already running but the session components died,
# bring them back without restarting the server.
if [ "$SESSION" = "plasma" ] && ! pgrep -x kwin_x11 >/dev/null 2>&1; then
  KWIN_COMPOSE=N setsid kwin_x11 --replace </dev/null >"$HOME/.local/state/kwin.log" 2>&1 &
  sleep 1
fi

if [ "$SESSION" = "openbox" ]; then
  if ! pgrep -x openbox >/dev/null 2>&1; then
    setsid openbox-session </dev/null >"$HOME/.local/state/openbox.log" 2>&1 &
    sleep 1
  fi
  pgrep -x tint2 >/dev/null 2>&1 || \
    setsid tint2 -c "$HOME/.config/tint2/tint2rc" </dev/null >"$HOME/.local/state/tint2.log" 2>&1 &
  pgrep -x devilspie2 >/dev/null 2>&1 || \
    setsid devilspie2 </dev/null >"$HOME/.local/state/devilspie2.log" 2>&1 &
fi

# Bring the Termux:X11 app to the foreground.
am start --user 0 --windowingMode 1 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || \
  am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true
