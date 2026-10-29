# Reproducing the tablet setup

This is the full checklist for a new Android device. The target device is
arm64 and runs a recent Android version; this setup was developed on a Xiaomi
Pad running Android 16.

## 1. Install the base Termux APK

Install the **GitHub debug** build of Termux. Do not mix Play Store, F-Droid and
GitHub builds: the Termux plugins must use the same signing key.

- Termux `0.118.3`, universal debug APK
- Project: <https://github.com/termux/termux-app/releases/tag/v0.118.3>

Open Termux once and allow it to finish its first-run setup.

## 2. Clone this repository

```bash
pkg install git -y
git clone https://forgejo.sakul-flee.de/SakulFlee/TermuxSetup ~/TermuxSetup
cd ~/TermuxSetup
```

If the repository is private, authenticate with your Forgejo account or copy
the repository over from the workstation.

## 3. Review the device configuration

`setup.sh` creates `config.env` from `config.example` on first run. If this is
not the reference tablet, edit it before running setup:

```bash
cp config.example config.env
nano config.env
```

At minimum check:

- `OPENCODE_HOST` — workstation used by the OpenCode widget
- `AUTHORIZED_KEY` — SSH public key allowed to log in to this device
- `DPI` and `SESSION`
- `SYNCTHING_FOLDER` and `SYNCTHING_FOLDER_ID`

`config.env` is ignored by git.

## 4. Run setup

Run it from the **Termux app**, not from an SSH session and not through
`adb shell run-as`:

```bash
bash setup.sh
```

The script will:

- install `x11-repo` and the Termux packages from `packages.txt`;
- download and checksum the plugin APKs;
- open Android's package installer for Termux:API, Termux:Boot, Termux:Widget
  and Termux:X11;
- verify signatures and the Termux:X11 shared UID;
- install scripts/configuration and provision storage/services.

You must tap **Install** in Android for each APK. The base Termux app is already
installed and is not reinstalled by the script.

If there is a signature conflict, uninstall the old plugin (the old app data
may be lost) and rerun with the GitHub debug APK.

## 5. Manual Android permissions

These are special access settings, not normal app permissions:

1. **Termux:API**
   - Settings → Apps → Termux:API → Special app access → Modify system settings
   - Allow.
   - This is required for Plasma's brightness control. Without it,
     `termux-brightness` shows a “Please enable permission for Termux:API”
     toast.

2. **Termux**
   - Display over other apps → Allow.
   - Battery → Unrestricted / no optimisation.

3. Optional on Android 12+ if long-running processes are killed:

   ```bash
   adb shell settings put global settings_enable_monitor_phantom_procs false
   ```

## 6. Termux:X11 settings

Open the Termux:X11 app and set:

- `displayStretch=false`
- `forceOrientation=auto`
- the desired resolution/DPI

The display should fill the screen. If HyperOS PC/freeform mode is active,
exit PC mode or maximise Termux:X11.

## 7. Start the desktop

From Termux:

```bash
~/.local/bin/start-desktop.sh
```

Then run the Plasma touch tuning once:

```bash
~/.local/bin/plasma-tune.sh
```

To use the Openbox fallback, set `SESSION=openbox` in
`~/.config/tablet-session` and restart the desktop.

## 8. Firefox and yt-dlp

1. Open Firefox.
2. Log in to the sites you need.
3. Test a download:

   ```bash
   ytdl 'https://www.youtube.com/watch?v=jSYY-zTUOmU'
   ```

Downloads go to:

```text
/storage/emulated/0/Download/ytdlp
```

X/Twitter tracking parameters are stripped automatically. Other sites keep
their query parameters.

## 9. Syncthing

Start Syncthing once and get the device ID:

```bash
syncthing serve --home ~/.local/state/syncthing
```

Add the device ID to the peer (Dendra or HomeLab) and share the `personal`
folder. The peer-side examples are in
[`docs/nixos-integration.md`](docs/nixos-integration.md).

On the tablet, run the initial sync while charging:

```bash
~/.local/bin/syncthing-sync.sh --initial
```

Then register the daily job:

```bash
termux-job-scheduler --script ~/.local/bin/syncthing-sync.sh \
  --job-id 4242 --period-ms 86400000 \
  --network unmetered --battery-not-low true --storage-not-low true \
  --persisted true
```

The folder is receive-only by default. The sync script starts Syncthing,
unpauses the folder, waits, pauses it again and stops the service.

## 10. SSH

The SSH server starts at boot through Termux:Boot. The key in `config.env` is
authorized on the tablet.

From the workstation:

```bash
ssh -p 8022 u0_a510@<tablet-ip>
```

or add an SSH alias:

```sshconfig
Host tablet
  HostName 192.168.178.106
  Port 8022
  User u0_a510
```

Allocate a DHCP reservation for the tablet IP. There is no permanent
wake-lock; wake the tablet or open Termux if it is suspended.

## 11. Optional: full Termux home backup

For an identical-device clone, Termux provides:

```bash
termux-backup /sdcard/termux-backup.tar.gz
# on the target, after installing Termux:
termux-restore /sdcard/termux-backup.tar.gz
```

This is a fast device clone, not clean reprovisioning: it carries cookies,
keys, logs and device-specific state. Prefer `setup.sh` for a new device.

## 12. Verification checklist

- [ ] `termux-info` shows the expected Android/Termux versions
- [ ] all Termux plugin packages are installed and signed the same
- [ ] Termux:X11 opens and the desktop fills the screen
- [ ] Plasma panel is touch-sized and KWin manages windows
- [ ] Termux:Widget shortcuts are visible and work
- [ ] Firefox can log in and `ytdl` downloads to `Download/ytdlp`
- [ ] Syncthing device ID is added to the peer and initial sync works
- [ ] `ssh tablet` works from the workstation
- [ ] Termux:API brightness works without a permission toast
