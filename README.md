# lc-shell

A Wayland desktop shell for [Hyprland](https://hyprland.org), written from scratch in QML on [Quickshell](https://quickshell.org), with no C++ plugin.

It provides a bar, dashboards, a launcher, a lock screen, notifications, OSDs, a clipboard manager, a screenshot tool and a settings app. All of them follow one of five themes, in light and dark variants.

- **Multi-screen:** every screen has its own profile, recognised by its model, with its own bar, theme and dashboards. It was designed around a 5K ultrawide and a 2560×720 touch strip, the Corsair Xeneon Edge.
- **Five themes:** Classic, Constellation, Façade, Modulaire and Matrix. Each one is a full design language, not just a palette. Light and dark switch by hand, on a schedule or with the sun.
- **Bar:** on any screen edge, full width or as islands, floating or framing the desktop. It has 17 widgets in three sizes, and you edit it in place by dragging widgets. Hover cards show details, and clicking opens the full panel.
- **Dashboards:** grids of resizable modules bound to workspaces:
  - clock, weather, media, synced lyrics, system, network, VU meter and spectrum;
  - quick settings, Philips Hue lights, workspaces and window slots.
  - Modules redesign themselves for larger cells.
- **Launcher:** applications, actions, emoji, files, a calculator and wallpapers.
- **Lock screen and idle:** a PAM lock screen with a safe preview, idle rules, and turning screens off or suspending after locking.
- **Notifications:** a notification server with history, Do Not Disturb, and no popups over full-screen windows.
- **Clipboard manager:** history with pins, tags, previews and direct paste. Copies flagged as sensitive by password managers are ignored.
- **Screenshot tool:** frozen screens, area or window selection, and annotation in place.
- **Settings app:** applied live, with keyboard search.
- **Languages:** English and French interface.

> [!NOTE]
> This is a personal shell, shared as-is. It targets Hyprland only and follows recent Quickshell and Hyprland releases closely. Expect rough edges outside the setup it was built on.

## Requirements

**Required:**

- **Hyprland 0.57+.** Some features use the Lua configuration: the lock shortcut applied by the shell and the bindings in `contrib/hypr/`.
- **[Quickshell](https://quickshell.org) 0.3+**, a recent git build (`Quickshell.Networking` is required). On Arch: `quickshell-git` from the AUR.
- **PipeWire** with WirePlumber, **NetworkManager**, **BlueZ**, **UPower** and **power-profiles-daemon**, used through Quickshell's services.
- `python3`, `curl`, `wl-clipboard`, `grim`.

**Optional, enabling specific features:**

| Package | Used for |
|---|---|
| `fd` | File search in the launcher |
| `libqalculate` (`qalc`) | Calculator in the launcher |
| `cava` | Audio spectrum (media and VU modules) |
| `brightnessctl` | Laptop backlight |
| `ddcutil` | Brightness of external monitors (DDC/CI) |
| `lm_sensors` | CPU temperatures |
| `libnotify` (`notify-send`) | Notifications sent by the shell's scripts |
| `tailscale` | Tailscale status in the VPN controls |
| `hyprlock` | Fallback lock screen when the shell isn't running (`contrib/hypr/lock-and-dpms.sh`) |
| `playerctl` | Media keys in `contrib/hypr/shell.lua` |
| `huectl` in `~/.local/bin` | Philips Hue lights (module, widget, panel). This CLI is not part of this repository |

On Arch Linux:

```sh
paru -S quickshell-git
sudo pacman -S --needed pipewire wireplumber networkmanager bluez upower power-profiles-daemon \
    python curl wl-clipboard grim fd libqalculate cava brightnessctl ddcutil lm_sensors \
    libnotify playerctl hyprlock
```

Fonts and icons are bundled: no font package is needed.

## Installation

Quickshell looks for named configurations in `~/.config/quickshell/<name>`. Clone the repository there under the name `lc`:

```sh
git clone https://github.com/<owner>/lc-shell ~/.config/quickshell/lc
qs -c lc
```

You can also clone it anywhere else and symlink it to `~/.config/quickshell/lc`. Quickshell reloads the shell whenever a file changes.

Only one desktop shell should run at a time. Stop any other bar, notification daemon or wallpaper tool first. lc-shell's notification server waits until the `org.freedesktop.Notifications` name is free.

### Starting it with Hyprland

`contrib/hypr/` contains a ready-made set of bindings and helpers:

- **`shell.lua`:** global shortcuts for the launcher, clipboard, screenshots, notifications, theme and lock, plus media keys, and it starts the shell at login.
- **`lc-shell-loop.sh`:** restarts the shell if it stops, which the lock screen relies on.
- **`lock-and-dpms.sh`:** locks, then turns the screens off after a few seconds, falling back to `hyprlock`.

```sh
sh ~/.config/quickshell/lc/contrib/hypr/install.sh   # copies them to ~/.config/hypr (backups: *.orig)
```

Then load the bindings from your `hyprland.lua`:

```lua
require("shell")
```

You can also start it yourself with `exec-once = qs -c lc` (or `hl.exec_cmd("qs -c lc")`) and bind only the global shortcuts you want (see [Shortcuts](#global-shortcuts)).

For the lock screen to survive a shell crash, set `allow_session_lock_restore = true` in the `misc` section of your Hyprland config. With it, a restarted shell takes the lock back.

### Updating

```sh
git -C ~/.config/quickshell/lc pull
```

Hot reload picks up most changes. After an update that adds fonts or singletons, restart the shell (`qs -c lc kill`, then start it again).

## Configuration

Most settings are available in the **Settings** app (`Super+Space`, then "Settings", or `qs -c lc ipc call settings toggle`). Settings apply live.

Configuration has two layers, both reloaded live:

- `config/defaults.json` (in the repository): generic defaults. Don't edit it.
- `~/.config/lc/settings.json` (`$XDG_CONFIG_HOME/lc`): **your settings**, merged over the defaults. The Settings app and IPC write to it too. Objects merge key by key; lists (widgets, screens, cells) replace.

Example:

```json
{
  "language": "auto",
  "appearance": {
    "variant": "auto",
    "schedule": { "type": "sun", "latitude": 48.85, "longitude": 2.35 },
    "themes": { "normal": "constellation", "modules": "matrix" }
  },
  "modes": {
    "normal": {
      "bar": {
        "position": "top",
        "style": "islands",
        "floating": true,
        "left": ["workspaces", "window"],
        "center": ["clock"],
        "right": ["tray", "media", "network", "bluetooth", "battery", "volume", "notifications"]
      },
      "osd": { "position": "bottom", "margin": 80 }
    }
  },
  "screens": [
    { "match": { "model": "XENEON EDGE" }, "touch": true, "bar": null },
    { "match": { "name": "eDP-*" }, "theme": "classic" }
  ]
}
```

- **Screens:** a profile is recognised by `model`, which stays stable even when the connector changes (with an eGPU, for example), or by `name` (a connector pattern such as `eDP-*`). The first matching profile wins. A profile overrides the mode's `bar` and `osd` key by key, and `null` disables one. It can also set `theme`, `touch` and `frame`.
- **Themes:** `classic` (the default), `constellation`, `facade`, `modulaire` and `matrix`. `appearance.themes.normal` applies to bars and panels, and `appearance.themes.modules` to dashboards. A screen profile can override both with `"theme"`.
- **Light and dark:** `variant` is `dark`, `light` or `auto`. With `auto`, `schedule` uses fixed times (`"type": "time", "light": "07:30", "dark": "19:30"`) or the sun (`"type": "sun"`, `latitude`, `longitude`, computed locally).
- **Bar:**
  - `position` puts it on any edge: `top`, `bottom`, `left` or `right`.
  - Widgets go in `left`, `center` and `right` (from top to bottom on a vertical bar). A zone can hold several islands, as a list of lists.
  - The theme sets the bar's look, which you can override with `style` (`full` or `islands`), `floating`, `margin`, `radius`, `opacity`, `border`, `padding`, `spacing`, `height`, `verticalWidth`, `length` and `screenCorners`.
- **Frame:** `"frame": true`, or `{ "enabled": true, "thickness": 8, "innerRadius": 18, "outline": 1 }`, draws a ring around the desktop. The bar is its thick side. The frame is drawn under windows and hidden in full screen.
- **Bar editing:** right-click the bar outside its widgets, or run `qs -c lc ipc call bar edit`. Then:
  - drag widgets to move them, and use "+" at the end of a zone to start a new island;
  - click a widget for its size (S/M/L), zone or removal, and open a palette to add widgets;
  - undo, redo or discard, and finish with Esc.
  - Changes go to the screen's profile.
- **Widgets:** `workspaces`, `window`, `clock`, `media`, `volume`, `network`, `wifi`, `bluetooth`, `battery`, `system`, `weather`, `notifications`, `tray`, `quickSettings`, `lights`, `modes` and `dynamicIsland`.
  - Hovering one for 350 ms shows its card, and clicking opens its full panel.
  - An unknown name shows as `?name` in red.

See [`docs/bar-editing.md`](docs/bar-editing.md) and [`docs/themes.md`](docs/themes.md) for more.

## Dashboards

A dashboard is a grid of modules drawn under the windows, on the `bottom` layer. Dashboards are saved as **presets** and bound to **workspaces**: when a workspace bound to a preset is active, its screen shows that dashboard.

Edit them in Settings › Dashboard, or with the dashboard editor: drag, resize, add and remove modules. The grid adapts to the free space of each screen.

```json
"dashboards": {
  "grid": { "cellWidth": 200, "cellHeight": 165, "gap": 12, "margin": 12 },
  "windows": { "enabled": true, "ignore": ["steam"], "only": [] },
  "presets": {
    "Desk": {
      "cells": [
        { "type": "clock",  "x": 0, "y": 0, "w": 3, "h": 2 },
        { "type": "media",  "x": 3, "y": 0, "w": 3, "h": 2 },
        { "type": "window", "x": 6, "y": 0, "w": 6, "h": 4 }
      ]
    }
  },
  "workspaces": { "7": "Desk" }
}
```

**Modules:**

| Module | Shows |
|---|---|
| `clock` | Time, date and calendar |
| `weather` | Current conditions and forecast |
| `media` | Player with cover art and controls |
| `lyrics` | Synced lyrics |
| `system` | CPU, GPU, RAM, temperatures and processes |
| `network` | Traffic graphs and connection |
| `vu` | VU meter of the default output |
| `toggles` | Quick settings |
| `hue` | Philips Hue rooms and scenes |
| `workspaces` | Workspaces |
| `window` | Window slot |
| `themeSwitch` | Theme switcher |

- Modules adapt to their size: from a single cell up to large and "poster" layouts with more detail.
- **Window slots:** a window that opens on a workspace of that screen becomes floating and is placed in the first free `window` cell. Full-screen windows are left alone. `windows.ignore` and `windows.only` filter windows by class.

**Online services:**

- **Weather:** [Open-Meteo](https://open-meteo.com), no API key. Weather stays off until you pick a place in Settings › Weather, and only that place's coordinates are sent.
- **Lyrics:** [LRCLIB](https://lrclib.net). Only the artist, title and duration are sent, and lyrics are cached locally.

## Lock screen and idle

Configure it in Settings › Lock, or in the `lock` and `idle` sections of `settings.json`.

- **Shortcut:** `lock.shortcut` defaults to `SUPER + Escape`. The shell binds it in Hyprland itself, through `hyprctl eval`, and binds it again after every config reload.
- **After locking:** `lock.afterLock` is `screensOff`, `suspend` or `none`, after `lock.afterLockDelay` seconds (5 by default). Typing or moving the mouse cancels it.
- **Lock screen:** one surface per screen (`ext-session-lock`) with:
  - a blurred wallpaper, the time and date;
  - your picture (`~/.face`) and name;
  - the password field (with a Caps Lock warning), battery, and power buttons that need a double click.
  - Authentication uses PAM: `lock.pamService`, `hyprlock` by default.
- **Preview:** `qs -c lc ipc call lock preview` shows the same screen in a window. It checks your password for real but locks nothing. Failed attempts still count towards `pam_faillock`.
- **Other triggers:** `loginctl lock-session`, idle, and before suspend (`lock.beforeSleep`, using a `systemd-inhibit` delay lock).
- **Idle**, in seconds (0 means never):
  - `lock` 900, `screenOff` 930, `lockedScreenOff` 30, `suspend` 1800;
  - `inhibitWhenAudio` keeps the session awake while an MPRIS player is playing;
  - `inhibitWhenCharging` does the same on AC power;
  - idle inhibitors from apps and Hyprland are respected;
  - the "caffeine" toggle in quick settings keeps the session awake until you turn it off.

## Launcher

`Super+Space` (`lc:launcher`), `qs -c lc ipc call launcher toggle`, or `openWith ":"` to open it directly in a mode.

| Prefix | Mode | Enter | Shift+Enter / right-click |
|---|---|---|---|
| (none) | Apps, actions, and calculation when the input looks like one | launch | |
| `:` | Emoji (English and French names, CLDR) | type and copy | copy only |
| `/` | Files in `~` (`fd`, no hidden or ignored files) | open | open the folder |
| `=` | Calculator (`qalc`: units, currencies…) | copy the result | |
| `>` | Actions: lock, suspend, log out, reboot, power off, reload, audio output/input | run | |
| `@` | Wallpapers | all screens | this screen only |
| `+` | Clipboard history | paste | copy |

Tab switches modes. Destructive actions ask for confirmation. Results are ranked by usage.

## Clipboard

`Super+Shift+V` (`lc:clipboard`) opens the history on the active screen.

- **Capture:** `wl-paste --watch` runs `clipboard/capture.py` (Python, no dependencies) on every copy. It keeps the most useful type and stores it in `$XDG_DATA_HOME/lc/clipboard/`, a mode-700 folder. The same content is never stored twice: it moves back to the top.
- **Types:** text, code, links, colours, emoji, images and files, each with a preview.
- **Organising:** tabs (All, Pinned, one per tag), type filter and search. Pinned and tagged items are kept indefinitely.
- **Pasting:**
  - Enter copies the item and pastes it into the previously focused window (Ctrl+Shift+V in the listed terminals);
  - Shift+Enter only copies;
  - Ctrl+1…9 picks an item, and Space opens a large preview.
- **Privacy:**
  - copies flagged as sensitive by password managers are ignored (`x-kde-passwordManagerHint`);
  - so are copies from the apps listed in `ignoreApps`;
  - an "incognito" pause (`lc:clipboardIncognito`, Ctrl+I) stops recording.

```json
"clipboard": {
  "enabled": true,
  "position": "bottom",
  "maxItems": 500,
  "maxDays": 0,
  "keepTagged": true,
  "images": true, "maxImageMB": 20,
  "ignoreSensitive": true,
  "ignoreApps": ["org.keepassxc.KeePassXC", "Bitwarden"],
  "pasteOnEnter": true,
  "terminals": ["kitty", "foot", "Alacritty"]
}
```

`position` sets where the history opens:
- `bottom` or `top`: a strip of cards;
- `left` or `right`: a column;
- `center`: a list with a large preview;
- `pointer`: a compact column under the mouse.

## Screenshots

`Print` (`lc:screenshot`) freezes every screen and opens the editor over them.

- **Selection:**
  - drag for an area, click for the window under the pointer, or press Ctrl+A for the whole screen;
  - a magnifier shows real pixel coordinates;
  - handles and arrow keys adjust the selection.
- **Annotation:** pen, highlighter, line, arrow, rectangle, ellipse, text, numbered steps and pixelation. There are 8 colours and 3 widths, with undo and redo.
- **Result:** rendered at the screen's real resolution.
  - Enter copies, Ctrl+S saves.
  - A notification then offers Annotate, Save or Open.
- **Immediate shots:** `Shift+Print` captures the focused screen and `Ctrl+Print` the active window. Both are copied right away.
- **Settings:** in the `screenshot` section (`dir`, `fileName`, `enterAction`, `copyOnSave`…). The default folder is `~/Pictures/Screenshots` (XDG pictures folder).

## Notifications and OSD

- **Notification server:** lc-shell has its own `org.freedesktop.Notifications` server.
  - Popups appear on the active screen and pause while hovered. Critical notifications stay until you close them.
  - No popups appear over a full-screen window: they move to another screen or wait.
  - With Do Not Disturb, notifications go to the history only. The history keeps 100 notifications across restarts.
  - Bodies are shown as plain text, so no remote images are loaded.
- **OSD:** the OSD reacts to **changes** in PipeWire and the backlight, not to keys. Your volume and brightness bindings can therefore stay on `wpctl` and `brightnessctl`, and keep working while the shell is stopped. External monitors (DDC/CI) go through the `brightness` IPC.

## Languages

The interface is in English or French. Set `"language"` to `auto` (follows the system locale), `en` or `fr`, and `"locale"` to force a date and number format (for example `en_GB`). Switch live with `qs -c lc ipc call i18n set en|fr|auto`.

Strings live in `i18n/<lang>.json`. Missing keys fall back to English. To add a language:
1. Copy `en.json` and translate it.
2. Add the code to `I18n.languages`.
3. For emoji names, add the CLDR annotations to `tools/gen-emoji.py`.

## IPC

`qs -c lc ipc show` lists every target and function. The main ones:

| Command | Effect |
|---|---|
| `bar toggle` / `edit` / `panel <widget>` | Bars, edit mode, panels |
| `launcher toggle` / `openWith <text>` | Launcher |
| `settings toggle` / `openPage <page>` | Settings |
| `audio increment` / `decrement` / `toggleMute` / `toggleMicMute` | Default output volume |
| `media togglePlaying` / `next` / `previous` / `cycle` | Active player |
| `brightness increment` / `decrement` | Brightness of the focused screen |
| `theme set <id>` / `setModules <id>` / `variant dark\|light\|auto` / `toggleVariant` | Themes |
| `i18n set en\|fr\|auto` | Interface language |
| `notifs toggleDnd` / `clear` | Notifications |
| `wallpaper set <path>` / `setHere <path>` / `random` | Wallpaper (all screens / active screen) |
| `lock lock` / `preview` / `isLocked` | Lock screen |
| `clipboard toggle` / `togglePause` / `clear` | Clipboard |
| `shell screenshot` / `screenshotScreen` / `screenshotWindow` / `screenshotEdit <file>` | Screenshots |
| `shell reload` | Full reload |

Prefix every command with `qs -c lc ipc call`, for example `qs -c lc ipc call theme set matrix`.

## Global shortcuts

These are Hyprland global shortcuts: they are instant and start no process. Bind them with the `global` dispatcher:

```lua
hl.bind("SUPER + Space", hl.dsp.global("lc:launcher"))
```

| Name | Action |
|---|---|
| `lc:launcher` / `lc:emoji` / `lc:files` | Launcher (on emoji / file search) |
| `lc:clipboard` / `lc:clipboardIncognito` | Clipboard history / pause recording |
| `lc:screenshot` / `lc:screenshotScreen` / `lc:screenshotWindow` | Screenshots |
| `lc:notifications` / `lc:clearNotifs` / `lc:dnd` | Notifications |
| `lc:media` | Media card (player, lyrics) |
| `lc:settings` / `lc:editBar` | Settings / bar edit mode |
| `lc:toggleVariant` / `lc:nextTheme` | Light/dark, next theme |
| `lc:lock` | Lock |

## Project layout

| Path | Contents |
|---|---|
| `shell.qml` | Entry point: one `ScreenScope` per screen |
| `windows/` | Per-screen windows: bar, dashboard, launcher, OSD, notifications, clipboard, screenshot, wallpaper |
| `widgets/` | Bar widgets, plus `Registry.qml` (name → file) |
| `dashboard/` | Dashboard logic and `modules/` (with their own `Registry.qml`) |
| `cards/`, `panels/` | Hover cards and the panels they open |
| `components/` | Shared components; they read the theme of their window |
| `services/` | Singletons: config, screens, audio, players, network, Bluetooth, power, weather, IPC… |
| `theme/` | Theme registry, light/dark scheduling, `defs/` (one file per theme) |
| `settings/`, `lock/`, `launcher/`, `clipboard/` | Settings app, lock screen, launcher providers, clipboard capture |
| `i18n/` | `en.json`, `fr.json` |
| `config/defaults.json` | Default settings |
| `assets/` | Bundled fonts, icon fonts, shaders, theme wallpapers |
| `tools/` | Generators: icon font subset, emoji data, settings search index, wallpaper tiles, shaders |
| `contrib/hypr/` | Hyprland bindings and helper scripts |
| `docs/` | Architecture, themes, bar editing |

## Development

- Quickshell reloads the shell on every file change. A **new singleton** (`pragma Singleton`) or a new bundled font needs a full restart.
- Test settings in `~/.config/lc/settings.json` rather than in `config/defaults.json`.
- To add a widget, write `widgets/Xxx.qml` (properties `screen`, `options`) and register it in `widgets/Registry.qml`. Dashboard modules work the same way in `dashboard/modules/`.
- Icons come from a subset of Material Symbols. To use a new icon, add its name to `tools/icons.txt` and run `tools/gen-icons.py`.
- **Diagnostics:**
  - `qs log -c lc` for the log;
  - `qs -c lc ipc call bar blocks` for widget geometry;
  - `media info` and `lyrics status` for the player and lyrics.
- Popups (panels, hover cards) only open while their bar has the pointer.

## Credits

lc-shell is built on [Quickshell](https://quickshell.org). Its code was written from scratch; some defaults, like the idle timings, were inspired by [Caelestia](https://github.com/caelestia-dots/shell).

Bundled assets keep their own licenses (see the license file next to each):

- **Fonts, SIL Open Font License 1.1:**
  - Barlow Condensed, Doto (static instances renamed "Doto Matrix" / "Doto LCD"), DSEG7 / DSEG14 Classic;
  - Figtree, Geist Mono, IBM Plex Mono, IBM Plex Sans Condensed;
  - JetBrains Mono, Michroma, Nixie One, Outfit, Space Grotesk, Space Mono.
- **Icons:** a subset of [Material Symbols](https://github.com/google/material-design-icons) (Apache License 2.0).
- **Emoji data:** Unicode emoji and CLDR annotations (Unicode License v3; see `launcher/data/README.md`).

## License

[MIT](LICENSE) for the code. Bundled third-party assets keep their own licenses, listed above.
