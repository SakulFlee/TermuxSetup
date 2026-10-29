# Tablet Termux shell

A tablet environment for the Xiaomi Pad, built on Termux + Termux:X11.
**KDE Plasma 6 is the default session.** It provides proper scaling, KWin
window management, a touch-sized panel and Plasma's app launcher. The earlier
Openbox + tint2 + Rofi tablet shell is kept as a lightweight fallback.

## Current device

- Xiaomi `2509ARPBDG` (`flute`), Android 16 / SDK 36, arm64-v8a
- 7.8 GB RAM; `/sdcard/Personal` wiped, ~180 GB free for the initial sync
- 1600x2560 display, density 320
- Termux user `u0_a510`, tablet LAN IP `192.168.178.106`
- Dendra LAN IP `192.168.178.109`
- Syncthing device ID `D6FXOLT-K6ANSIJ-RLFA7D7-EPI6CZO-GVVCGET-B3NMYBA-ZJ34RF6-VXO3BQ5`
- Syncthing-Fork is disabled; native Syncthing owns the `personal` folder

## Components

- **Termux** (GitHub debug build) + **Termux:X11** shared-UID APK
- **Termux:API / Widget / Boot**
- **KDE Plasma 6** with KWin X11 (default session)
- **Dolphin** and **Konsole** (Plasma apps)
- **Openbox + tint2 + Rofi + devilspie2** (fallback tablet shell)
- **Firefox** with a dedicated tablet profile, touch density and software rendering
- **yt-dlp** wrapper that reads the live Firefox cookie DB (including WAL)
- **PulseAudio** (Termux's `module-sles-sink`)
- **OpenSSH** on port 8022
- **Syncthing** on `127.0.0.1:8384`
- **Dunst** for desktop notifications

## Install

Install the APKs first (same signing source!):

1. `termux-app_v0.118.3+github-debug_universal.apk`
2. `termux-api-app_v0.53.0+github.debug.apk`
3. `termux-boot-app_v0.8.1+github.debug.apk`
4. `termux-widget-app_v0.15.0+github.debug.apk`
5. `termux-x11-universal-sharedUid-debug.apk` (nightly)

Tasker is not used in this setup.

Then install the Termux packages:

```bash
pkg install x11-repo
pkg install termux-x11-nightly plasma dolphin konsole openbox tint2 rofi devilspie2 xvkbd \
  pcmanfm qterminal firefox python-yt-dlp yt-dlp-ejs deno ffmpeg \
  dbus pulseaudio openssh syncthing termux-api termux-services \
  termux-tools termux-am git jq ttf-dejavu pavucontrol lxappearance \
  obconf-qt xorg-xrdb xorg-xsetroot xorg-xdpyinfo wmctrl xdotool dunst
```

Copy this directory to the tablet and run `install.sh` from Termux:

```bash
bash install.sh
```

Then run the one-time provisioning **from the Termux app**:

```bash
~/.local/bin/provision.sh
```

The provisioning script must run in the Termux app's SELinux context so it can
create `~/storage` and let Syncthing access `/sdcard`. Do not run it via
`adb shell run-as`.

## Start / stop

From the Termux app, a widget, or SSH:

```bash
~/.local/bin/start-desktop.sh
~/.local/bin/stop-desktop.sh
```

The Termux:Widget shortcuts created by `install.sh` are:

- Start Desktop
- Stop Desktop
- Show Desktop
- Firefox
- Terminal
- Files
- Download Clipboard
- Download URL
- OpenCode
- Sync Now

**Download Clipboard** is the one-tap flow: copy a URL, tap it, get a
notification when the download finishes. **Download URL** opens a native
`termux-dialog` input instead. Both use the Firefox cookie profile and always
download the best quality.

Add the Termux:Widget widget to the home screen and pick the shortcuts. If the
widget starts the desktop but Termux:X11 does not come forward, grant Termux
**Display over other apps** (see Troubleshooting).

## Plasma session

The default session is Plasma:

```ini
SESSION=plasma
DISPLAY=:0
DPI=144
```

`start-desktop.sh` starts Plasma with `KWIN_COMPOSE=N` because Termux:X11 does
not provide a working OpenGL compositor; KWin otherwise exits and windows are
left unmanaged. After the first start, run:

```bash
~/.local/bin/plasma-tune.sh
```

This sets single-click, Plasma's touch mode, and an 80 px bottom panel.

Termux:X11 should use `displayStretch=false`; stretching a 1920x1200 desktop to
a different window size is what makes text and windows look distorted.

### HyperOS PC / freeform mode

If the keyboard case is attached, HyperOS can switch to PC/freeform mode. In
that mode Termux:X11 is a freeform window, so the X desktop is squeezed into a
window and the rest of the screen is the PC desktop. Exit PC mode from the
Control Center (`freeformhang` tile), detach the keyboard, or maximise the
Termux:X11 window. Plasma itself is fine once the X11 window fills the screen.

### Openbox fallback

Set `SESSION=openbox` in `~/.config/tablet-session`, then stop/start the
desktop. The tint2/Rofi shell is intentionally kept as a lightweight fallback.

## Cookies / yt-dlp

Firefox uses the dedicated profile `~/.mozilla/firefox/tablet`. Log in to any
site normally. `~/.local/bin/ytdl` copies `cookies.sqlite`, `cookies.sqlite-wal`,
`cookies.sqlite-shm` and `containers.json` to a temporary profile and runs
yt-dlp against it, so cookies created while Firefox is open are included.

```bash
ytdl 'https://example.com/video'
ytdl --list-formats 'https://example.com/video'
```

Downloads go to `~/storage/downloads/ytdlp` (Android Downloads).

## Syncthing (manual + daily)

Syncthing runs **on demand**, not continuously:

- **Sync Now** widget → `syncthing-sync.sh` (10 minute incremental run).
- A daily `termux-job-scheduler` job → the same script.
- The script starts the service, unpauses `personal`, waits for the sync to
  finish, pauses it again and stops the service.

The tablet’s `/sdcard/Personal` was wiped, leaving ~180 GB free, so the full
~65 GB global folder (Dendra + HomeLab) fits. The folder is set to
**receive-only**: the tablet mirrors the peers, and local deletions do not
propagate. Switch it to `sendreceive` later if you want tablet uploads.

Initial sync, on the charger:

```bash
~/.local/bin/syncthing-sync.sh --initial
```

The daily job:

```bash
termux-job-scheduler --script ~/.local/bin/syncthing-sync.sh \
  --job-id 4242 --period-ms 86400000 \
  --network unmetered --battery-not-low true --storage-not-low true \
  --persisted true
```

Remove it with:

```bash
termux-job-scheduler --cancel --job-id 4242
```

The GUI still listens on `127.0.0.1:8384`; from Dendra use an SSH tunnel:

```bash
ssh -L 8384:127.0.0.1:8384 -p 8022 u0_a510@192.168.178.106
```

The tablet's native Syncthing device ID is
`D6FXOLT-K6ANSIJ-RLFA7D7-EPI6CZO-GVVCGET-B3NMYBA-ZJ34RF6-VXO3BQ5`; it is
already added to Dendra's `hosts/Dendra/syncthing.nix`.

## SSH

- Port: 8022
- User: `u0_a510` (the Termux app UID; check with `whoami`)
- Key-only; `~/.ssh/authorized_keys` contains the `sakulflee@nixos` key.
- From Dendra: `ssh tablet` (the `Host tablet` entry is in the Home Manager SSH
  config), or explicitly:

  ```bash
  ssh -p 8022 u0_a510@192.168.178.106
  ```

- From another device, use the same command. Add that device’s public key from
  an already-authorized session:

  ```bash
  ssh tablet 'cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub
  ```

- The tablet does not hold a permanent wake-lock. If it is asleep, wake it/open
  Termux first; the `tablet-sshd` service is started at boot by Termux:Boot.
- From the tablet to Dendra: `ssh sakulflee@192.168.178.109`.

## Runtime files on the tablet

Keep these:

- `~/.local/bin/` — `start/stop-desktop`, `open-app`, `ytdl`, `syncthing-sync`,
  `download-*`, `show-desktop`, `plasma-tune`, …
- `~/.config/` — Plasma, the Openbox fallback, tint2, Rofi, qterminal, GTK and
  `tablet-session`
- `~/.shortcuts/` — Termux:Widget scripts
- `~/.termux/` — `termux.properties`, `boot/start-services.sh`
- `~/.ssh/` — `sshd_config`, `authorized_keys`, keys
- `~/.mozilla/firefox/tablet/` — Firefox profile and cookies
- `~/.local/state/syncthing/` — Syncthing config, keys and index
- `~/storage/shared/Personal/` — the actual synced files

Disposable:

- `~/.config/**/*.bak-*` and `~/.local/**/*.bak-*` — installer backups
- `~/.local/share/tablet-shell-src/` — staging copy; reinstall from the repo
- `~/bootstrap*.sh`, `~/dlg.out`, `~/yt-test.log`, `~/syncthing-sync.out`
- `~/.local/state/*-test.log`
- `~/storage/downloads/ytdlp/test-*`
- `~/.cpan/` — Perl build cache

Logs (`~/syncthing-sync.log`, `~/ytdlp.log`, `~/.local/state/*.log`) are safe to
delete when not troubleshooting. Do **not** delete `~/.local/state/syncthing`
or `~/storage/shared/Personal` while a sync is running or if you want to keep
the received data.

## OpenCode

Runs on Dendra, not on the tablet:

```bash
~/.local/bin/opencode-ssh.sh
```

The host is configured in `~/.config/tablet-session` as
`OPENCODE_HOST=sakulflee@192.168.178.109`.

## Troubleshooting

- **Black screen**: add `-legacy-drawing` to the `termux-x11` call in
  `start-desktop.sh`.
- **Swapped colours**: add `-force-bgra`.
- **X11 not connected**: start the desktop first, then open Termux:X11.
- **Plasma has no window decorations / windows are not managed**: KWin failed
  to start its compositor. Use `KWIN_COMPOSE=N` (the default here) and ensure
  `kwin_x11` is running. `start-desktop.sh` has a fallback that starts it.
- **Stretched or squashed desktop**: set Termux:X11 `displayStretch=false`.
  If HyperOS PC/freeform mode is active, Termux:X11 is a freeform window; exit
  PC mode or maximise the Termux:X11 window.
- **Plasma panel too thin**: run `~/.local/bin/plasma-tune.sh` (sets 80 px), or
  `qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript
  'panels()[0].height = 80'`.
- **No audio**: `pulseaudio --start --exit-idle-time=-1`; check
  `pactl info` and `pactl list short sinks`. If `module-sles-sink` fails, try
  `sed -i 's/module-sles-sink/module-aaudio-sink/g' $PREFIX/etc/pulse/default.pa`.
- **"Please enable permission for Termux:API" toast / Plasma brightness**:
  Plasma's PowerDevil backlight helper calls `termux-brightness`, which needs the
  special **Modify system settings** (`WRITE_SETTINGS`) access. It is not shown
  in the normal app permission list, so every normal permission can be granted
  and the toast still appears. Grant it via **Settings → Apps → Termux:API →
  Special app access → Modify system settings**, or from a computer with adb:

  ```bash
  adb shell appops set com.termux.api WRITE_SETTINGS allow
  ```

  Re-grant it after reinstalling Termux:API. Existing **Termux:API Error**
  notifications are leftovers from the failed calls and can be swiped away.
  Plasma's brightness slider may start at 50% because the Termux brightness API
  is write-only; setting it still works.
- **Clipboard empty**: Android 10+ restricts background clipboard access. Use
  the **Download URL** widget, which opens a native paste dialog.
- **Widget starts the desktop but Termux:X11 stays behind**: grant Termux
  **Display over other apps** (`adb shell appops set com.termux
  SYSTEM_ALERT_WINDOW allow`), use the normal Termux:Widget (not Termux:Tasks),
  and try the **Show Desktop** shortcut.
- **Rotation**: `forceOrientation=auto` follows the tablet. If Plasma does not
  reflow, use `~/.local/bin/set-orientation.sh landscape|portrait` (or
  `~/.local/bin/set-orientation.sh auto`) and restart the session.
- **Services die**: disable battery optimisation for Termux. There is no
  permanent wake-lock anymore; the desktop, download and sync scripts take one
  only while working. On Android 12+, the phantom process killer may need
  `adb shell settings put global settings_enable_monitor_phantom_procs false`.
- **Syncthing cannot see /sdcard**: `syncthing-sync.sh` must run in the Termux
  app context (`provision.sh` / widget / scheduler), not via `run-as`.
