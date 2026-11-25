# Design goals and requirements

The requirements and decisions behind lc-shell. Use this document to check that the implementation matches the actual needs, not just the mockups. The how is described in [`architecture.md`](architecture.md), [`themes.md`](themes.md) and [`bar-editing.md`](bar-editing.md).

## Context

- Arch, Hyprland 0.57 with **Lua config** (`hl.dsp.*`, no more `hyprctl keyword`).
- Laptop + eGPU setups: screens are hot-plugged and unplugged; connector names are unstable → screens are identified by **model**.
- Designed around a 5K ultrawide as the main monitor, a Corsair Xeneon Edge 2560×720 touch screen (touch-capable hardware, not yet working under Linux) and a laptop's internal panel (eDP).
- Fullscreen gaming with a controller is a core use case.
- lc-shell is developed while an existing shell (a Caelestia fork) **keeps running**; the switch-over happens in stages.

## Ground rules

1. **Bare Quickshell**, written from scratch. **No code** from Caelestia (GPL-3), from outfoxxed's config (no license) or from Nebula (AGPL-3.0): they are inspiration only. lc-shell itself is published under the MIT license.
2. **No imposed structure**: free widget layout, per screen.
3. **Nothing above a fullscreen game** for anything automatic (OSD, notifications, corners, frame); things invoked explicitly (launcher, panels) are still allowed.
4. **Multilingual** from the start: English and French to begin with.
5. **Touch** must be planned for (large targets, nothing that depends on hover).
6. Media keys go through `wpctl` / `brightnessctl` (they work with the shell stopped); the OSD reacts to the changes.
7. Lock and idle come **last**, with hyprlock as a fallback; a crash while locked = red screen.
8. **Raw features** first; the design gets polished afterwards, with a full review at the end.

## Required features

- Bar (permanent on “normal” screens); volume/brightness OSD; launcher; notifications (only one notification server can run → switch over in one go); wallpaper; idle and lock; IPC for keybinds.
- Audio: choice of inputs and outputs.
- Launcher: apps + actions (emoji, file search, calculator, lock, suspend…), then the settings screen.
- Widgets mentioned: audio, lyrics, monitoring, notifications, workspaces (open-ended list).

## Rendering and themes

- The design study's proposals are approved as the base. The Sérigraphie proposal was dropped; Ligne was replaced by a theme inspired by **Nebula** (→ Constellation).
- Selectable themes: **Classic** (default, used everywhere to start with), Constellation, Façade, Modulaire, **Matrix** (the author's own design language).
- **Light / dark** for every theme, with a schedulable switch: fixed times or sunrise/sunset; identical everywhere by default, configurable per screen later; set in the settings app (built at the end).

## Screens and bar

- Two **screen modes**, assignable per screen:
  - **normal**: permanent bar, classic layout; a laptop's internal panel is always normal;
  - **modules**: dashboard of modules (Xeneon), with an interface to choose/resize modules.
- The modules screen has **workspaces**: a free grid, with **window slots** where any Hyprland window can go (e.g. kitty on the secondary screen); ideally module workspaces (one page per workspace).
- Configurable bar: islands, full bar, floating or not, rounding, transparency, borders, corners… (defaults per theme, overridable); a **“frame” mode**, inspired by Caelestia's; bar **on any edge**.
- Every bar element: **rearrangeable, resizable, movable** elsewhere; polished **details on hover**.
- An **active window** widget (window title); the default placement of the date and time should be revisited accordingly (the layout remaining free).
- Bar: **full width** or **fixed width, centred**.
- Notifications at the top right by default, **configurable position**.
- Widgets open as **drawers** rather than floating bubbles: a drawer that **merges with the widget and its border**, “as if its area were growing” (in the spirit of Caelestia and Nebula).
- Polished **animations** when windows and menus open, not just plain fades.
- **App icons recolourable** to match the theme (bar, cards).

## Vocabulary

- **widget**: a bar element; **module**: an element of the modules screen (dashboard).

## Organisation

- Developed alongside the existing shell (`qs -c lc`, symlink `~/.config/quickshell/lc`).
- User settings live outside the repo (`~/.config/lc/settings.json`); the repo ships generic defaults.
- A design review is planned: compliance with the spec, quality, consistency, fit with the requirements and context.
