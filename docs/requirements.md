# Design goals and requirements

The goals and constraints behind lc-shell. They explain why the shell is built the way it is, and serve to check that the implementation meets the actual needs rather than just matching a look. How things work is described in [`architecture.md`](architecture.md), [`themes.md`](themes.md) and [`bar-editing.md`](bar-editing.md).

## Target setup

- Hyprland 0.57+ with its **Lua configuration** (`hl.dsp.*` dispatchers rather than `hyprctl keyword`), and only Hyprland.
- Multi-monitor setups where screens come and go, including laptops with an eGPU. Connector names are unstable there, so screens are identified by **model**.
- Designed around a 5K ultrawide main monitor, a Corsair Xeneon Edge 2560×720 touch screen used as a dashboard, and a laptop's internal panel. Nothing in the shell is specific to that hardware.
- Fullscreen gaming, including with a controller, must never be disturbed.

## Ground rules

1. **Bare Quickshell**, written from scratch, in QML with no C++ plugin. **No code** is taken from Caelestia (GPL-3.0), from outfoxxed's configuration (unlicensed) or from Nebula (AGPL-3.0). These projects are inspiration only, and the shell's code is MIT-licensed.
2. **No imposed structure**: widgets are laid out freely, per screen.
3. **Nothing above a fullscreen window** for anything automatic (OSD, notifications, screen corners, frame). What the user opens explicitly (launcher, panels, clipboard) is still allowed.
4. **Multilingual** from the start: English and French, with English as the fallback.
5. **Touch-friendly** where a screen is marked as touch: large targets, and nothing that only works on hover.
6. **Media keys keep working without the shell**: volume and brightness bindings go through `wpctl` / `brightnessctl`, and the OSD reacts to the resulting changes rather than to the keys.
7. **Locking is safe**: if the shell crashes while locked, the session stays locked (a red screen, `hyprlock` as a fallback) until a restarted shell takes the lock back.
8. **Settings stay out of the repository**: the repository ships generic defaults, and the user's settings live in `~/.config/lc/settings.json`.

## Features

- A bar, volume/brightness OSDs, a launcher, a notification server, wallpapers, idle handling and a lock screen, and IPC plus global shortcuts for keybinds.
- Audio: choice of the input and output devices.
- Launcher: applications plus actions (emoji, file search, calculator, lock, suspend…), and access to the settings app.
- Widgets and modules for audio, lyrics, system monitoring, notifications and workspaces, as an open-ended list.

## Look and themes

- Several complete themes, each a design language of its own: **Classic** (the default), **Constellation**, **Façade**, **Modulaire** and **Matrix** (the author's own design language).
- **Light and dark** variants for every theme, switched by hand, at fixed times, or at sunrise/sunset.
- **Polished animations** when windows and menus open, not just plain fades, with a reduced-motion option.
- **App icons recolourable** to match the theme (bar, cards).

## Screens, bar and dashboards

- **Per-screen profiles**: each screen can have its own bar layout, theme and touch setting.
- **Dashboards**: grids of modules (media, lyrics, monitoring, VU…) and **window cells** where any Hyprland window can be placed (e.g. a terminal on a small secondary screen). They are bound to workspaces, one dashboard per workspace, and edited with a dedicated interface for choosing, placing and resizing modules.
- **Configurable bar**: islands or a full bar, floating or not, rounding, transparency, borders, screen corners… (defaults per theme, overridable). It can also be shown in a **frame** mode, inspired by Caelestia's, placed **on any edge**, and drawn **full width** or as a **centred fixed-width** bar.
- **Every bar element** can be rearranged, resized and moved elsewhere, including to another screen, and shows a polished **detail card on hover**.
- **Active window** widget (window title), hidden while the screen is shared.
- **Notifications** at the top right by default, with a **configurable position**.
- **Drawers rather than floating bubbles**: a widget's panel or card opens as a drawer that **merges with the widget and its border**, as if the widget's area were growing (in the spirit of Caelestia and Nebula).

## Vocabulary

- **widget**: an element of the bar;
- **module**: an element of a dashboard.
