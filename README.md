# Termux Tablet Setup

A reproducible Termux + Termux:X11 + KDE Plasma tablet environment.

It provides a touch-friendly Plasma desktop, Firefox with a live-cookie
yt-dlp wrapper, Syncthing, SSH, and Termux:Widget shortcuts for the common
actions. The Openbox + tint2 shell is kept as a lightweight fallback.

## Quick start

The base Termux APK must be installed first; `setup.sh` runs inside it and
cannot install Termux itself.

1. Install **Termux 0.118.3 (GitHub debug, universal)**.
2. In Termux:

   ```bash
   pkg install git -y
   git clone https://forgejo.sakul-flee.de/SakulFlee/TermuxSetup ~/TermuxSetup
   cd ~/TermuxSetup
   bash setup.sh
   ```

3. Follow the Android prompts for the plugin APKs and storage access.
4. Do the manual steps printed at the end. The important ones are:

   - **Termux:API → Special app access → Modify system settings → Allow**
     (needed for Plasma brightness)
   - **Termux → Display over other apps → Allow**
   - **Termux → Battery → Unrestricted**

Full checklist for a new device: [`REPRODUCE.md`](REPRODUCE.md).

> Run `setup.sh` from the Termux app, not over SSH or `adb shell run-as`.
> Storage access and Android package installation need Termux's app context.

## What setup does

`setup.sh`:

- installs `x11-repo` and the packages listed in [`packages.txt`](packages.txt);
- downloads pinned APKs from [`apks.tsv`](apks.tsv), verifies SHA256, and opens
  each with Android's package installer;
- verifies all plugins use the same signing key as Termux and that Termux:X11
  uses Termux's shared UID;
- runs `install.sh` and `provision.sh`;
- writes a local `config.env` and the generated `~/.config/tablet-session`;
- prints the remaining Android/Termux:API steps.

Useful options:

```bash
bash setup.sh --skip-packages   # only APKs/files/provisioning
bash setup.sh --no-apks         # no APK download/install
bash setup.sh --apk-dir DIR     # use pre-downloaded APKs
bash setup.sh --force-apks      # re-open installed plugins
bash setup.sh --yes             # skip confirmation pauses
```

Android still requires a tap per plugin APK. A fully unattended install would
need ADB (`adb install`) from another machine.

Termux:X11 uses the shared-UID nightly asset. If upstream replaces the nightly
APK, its checksum changes; update `apks.tsv` or place the known-good APK in a
directory and use `--apk-dir`.

## Configuration

`setup.sh` creates `config.env` from [`config.example`](config.example).
`config.env` is git-ignored and holds device-specific values:

```ini
SESSION=plasma
DISPLAY=:0
DPI=144
OPENCODE_HOST=sakulflee@192.168.178.109
AUTHORIZED_KEY='ssh-ed25519 ...'
SYNCTHING_FOLDER=/sdcard/Personal
SYNCTHING_FOLDER_ID=personal
```

Edit it before running setup, or re-run `install.sh` after editing. The
generated `~/.config/tablet-session` is what the runtime scripts read.

## Reference device

- Xiaomi `2509ARPBDG` (`flute`), Android 16 / SDK 36, arm64-v8a
- 7.8 GB RAM, 1600x2560 display, density 320
- Termux user `u0_a510`, tablet LAN IP `192.168.178.106`
- Dendra LAN IP `192.168.178.109`
- Syncthing device ID
  `D6FXOLT-K6ANSIJ-RLFA7D7-EPI6CZO-GVVCGET-B3NMYBA-ZJ34RF6-VXO3BQ5`
- Syncthing-Fork is disabled; native Syncthing owns the `personal` folder

Other devices work too; update `config.env`, the SSH key, the Syncthing device
ID and the SSH/Syncthing entries on the peer.

## Components

- **Termux** (GitHub debug build) + **Termux:X11** shared-UID APK
- **Termux:API / Widget / Boot**
- **KDE Plasma 6** with KWin X11 (default session)
- **Dolphin** and **Konsole**
- **Openbox + tint2 + Rofi + devilspie2** (fallback)
- **Firefox** with a dedicated tablet profile, touch density and software rendering
- **yt-dlp** wrapper that reads the live Firefox cookie DB (including WAL)
- **PulseAudio** (Termux's `module-sles-sink`)
- **OpenSSH** on port 8022
- **Syncthing** on `127.0.0.1:8384`
- **Dunst** for desktop notifications

## Manual install (fallback)

If you do not want to run `setup.sh`, install the APKs in `apks.tsv` in order,
then run:

```bash
pkg install x11-repo
grep -vE '^[[:space:]]*(#|$)' packages.txt | xargs pkg install -y
bash install.sh
bash provision.sh
```

All Termux plugins must come from the same signing source as Termux. The
GitHub debug builds are used here. Termux:X11 must be the
`termux-x11-universal-sharedUid-debug.apk` build.

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
a different window size makes text and windows look distorted.

### HyperOS PC / freeform mode

If the keyboard case is attached, HyperOS can switch to PC/freeform mode. In
that mode Termux:X11 is a freeform window, so the X desktop is squeezed into a
window and the rest of the screen is the PC desktop. Exit PC mode from the
Control Center (`freeformhang` tile), detach the keyboard, or maximise the
Termux:X11 window.

### Openbox fallback

Set `SESSION=openbox` in `~/.config/tablet-session`, then stop/start the
desktop. The tint2/Rofi shell is intentionally kept as a lightweight fallback.

## Downloads and URL cleanup

Downloads go to Android's shared Downloads folder:

```text
~/storage/downloads/ytdlp
/storage/emulated/0/Download/ytdlp
```

Override with `YTDLP_OUT`:

```bash
YTDLP_OUT=~/storage/shared/MyVideos ytdl 'https://example.com/video'
```

`clean-url.sh` removes the entire query string and fragment from **X/Twitter**
URLs, stripping tracking parameters such as `?a=...&s=20`. Other sites keep
their parameters, so YouTube's `?v=`, `?list=` and `?t=` still work.

It is applied by both download widgets and by `ytdl`. Test it with:

```bash
bash tests/clean-url.sh
```

Because the rule is host-based, X search/login links also lose their query
parameters. That is intentional for the downloader; narrow the rule to status
URLs if you ever need those links.

## Cookies / yt-dlp

Firefox uses the dedicated profile `~/.mozilla/firefox/tablet`. Log in to any
site normally. `~/.local/bin/ytdl` copies `cookies.sqlite`,
`cookies.sqlite-wal`, `cookies.sqlite-shm` and `containers.json` to a temporary
profile and runs yt-dlp against it, so cookies created while Firefox is open
are included.

```bash
ytdl 'https://example.com/video'
ytdl --list-formats 'https://example.com/video'
```

## Syncthing (manual + daily)

Syncthing runs **on demand**, not continuously:

- **Sync Now** widget → `syncthing-sync.sh` (10 minute incremental run).
- A daily `termux-job-scheduler` job → the same script.
- The script starts the service, unpauses the configured folder, waits for the
  sync to finish, pauses it again and stops the service.

The folder is **receive-only** by default: the tablet mirrors the peers, and
local deletions do not propagate. Switch it to `sendreceive` later if you want
tablet uploads.

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

The GUI listens on `127.0.0.1:8384`; from a workstation use an SSH tunnel:

```bash
ssh -L 8384:127.0.0.1:8384 tablet
```

Get the tablet's device ID after the first Syncthing start and add it to the
peer. The Dendra snippets are in
[`docs/nixos-integration.md`](docs/nixos-integration.md).

## SSH

- Port: `8022`
- User: the Termux app UID (normally `u0_a510`; check `whoami`)
- Key-only; the key in `config.env` is added to `~/.ssh/authorized_keys`.
- `install.sh` creates `~/.ssh/id_ed25519` if it is missing. Add its `.pub`
  file to the workstation's `authorized_keys` for the tablet → workstation
  direction (OpenCode).
- From a workstation with a `Host tablet` entry:

  ```bash
  ssh tablet
  ```

  or explicitly:

  ```bash
  ssh -p 8022 u0_a510@192.168.178.106
  ```

- Add another device's key from an authorized session:

  ```bash
  ssh tablet 'cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub
  ```

- Set a DHCP reservation for the tablet IP so the alias stays valid.
- The tablet has no permanent wake-lock. If it is asleep, wake it/open Termux;
  `tablet-sshd` is started at boot by Termux:Boot.
- From the tablet to the workstation: `ssh sakulflee@192.168.178.109`.

## Runtime files

Keep:

- `~/.local/bin/` — scripts, `ytdl`, `clean-url.sh`
- `~/.config/` — Plasma, Openbox, tint2, Rofi, qterminal, GTK and
  `tablet-session`
- `~/.shortcuts/` — Termux:Widget scripts
- `~/.termux/` — `termux.properties`, `boot/start-services.sh`
- `~/.ssh/` — `sshd_config`, `authorized_keys`, keys
- `~/.mozilla/firefox/tablet/` — Firefox profile and cookies
- `~/.local/state/syncthing/` — Syncthing config, keys and index
- `~/storage/shared/Personal/` — the synced files

Disposable:

- `config.env` backups and `*.bak-*` installer backups
- `~/.local/share/tablet-shell-src/` — staging copy
- `~/bootstrap*.sh`, `~/dlg.out`, `~/yt-test.log`, `~/syncthing-sync.out`
- `~/.local/state/*-test.log`
- `~/storage/downloads/ytdlp/test-*`
- `~/.cpan/` — Perl build cache

Logs (`~/syncthing-sync.log`, `~/ytdlp.log`, `~/.local/state/*.log`) are safe to
delete when not troubleshooting. Do **not** delete `~/.local/state/syncthing`
or `~/storage/shared/Personal` while a sync is running or if you want the
received data.

## OpenCode

OpenCode runs on the workstation, not the tablet:

```bash
~/.local/bin/opencode-ssh.sh
```

The host is configured in `config.env` as `OPENCODE_HOST`.

## NixOS integration

Dendra-side SSH, authorized-key and Syncthing snippets are in
[`docs/nixos-integration.md`](docs/nixos-integration.md). The Termux device
setup itself lives entirely in this repository.

## Troubleshooting

- **Black screen**: add `-legacy-drawing` to the `termux-x11` call in
  `start-desktop.sh`.
- **Swapped colours**: add `-force-bgra`.
- **X11 not connected**: start the desktop first, then open Termux:X11.
- **Plasma has no window decorations / windows are not managed**: KWin failed
  to start its compositor. Use `KWIN_COMPOSE=N` and ensure `kwin_x11` is
  running. `start-desktop.sh` has a fallback that starts it.
- **Stretched or squashed desktop**: set Termux:X11 `displayStretch=false`.
  If HyperOS PC/freeform mode is active, exit PC mode or maximise the window.
- **Plasma panel too thin**: run `~/.local/bin/plasma-tune.sh` (sets 80 px), or
  `qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript
  'panels()[0].height = 80'`.
- **No audio**: `pulseaudio --start --exit-idle-time=-1`; check
  `pactl info` and `pactl list short sinks`. If `module-sles-sink` fails, try
  `sed -i 's/module-sles-sink/module-aaudio-sink/g' $PREFIX/etc/pulse/default.pa`.
- **"Please enable permission for Termux:API" / Plasma brightness**: Plasma's
  PowerDevil backlight helper calls `termux-brightness`, which needs the special
  **Modify system settings** (`WRITE_SETTINGS`) access. It is not in the normal
  permission list. Grant it via **Settings → Apps → Termux:API → Special app
  access → Modify system settings**, or:

  ```bash
  adb shell appops set com.termux.api WRITE_SETTINGS allow
  ```

  Re-grant after reinstalling Termux:API. Plasma's brightness slider may start
  around 50% because the Termux brightness API is write-only; setting it works.
- **Clipboard empty**: Android 10+ restricts background clipboard access. Use
  the **Download URL** widget, which opens a native paste dialog.
- **Widget starts the desktop but Termux:X11 stays behind**: grant Termux
  **Display over other apps** (`adb shell appops set com.termux
  SYSTEM_ALERT_WINDOW allow`), use the normal Termux:Widget (not Termux:Tasks),
  and try the **Show Desktop** shortcut.
- **Rotation**: `forceOrientation=auto` follows the tablet. If Plasma does not
  reflow, use `~/.local/bin/set-orientation.sh landscape|portrait` (or `auto`)
  and restart the session.
- **Services die**: disable battery optimisation for Termux. The desktop,
  download and sync scripts take a wake-lock only while working. On Android
  12+, the phantom process killer may need:

  ```bash
  adb shell settings put global settings_enable_monitor_phantom_procs false
  ```

- **Syncthing cannot see `/sdcard`**: `syncthing-sync.sh` must run in the
  Termux app context (`provision.sh` / widget / scheduler), not via `run-as`.
