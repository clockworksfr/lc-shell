# Target architecture

This document describes where the shell is heading; the README describes what exists today.

## Screens: profiles and modes

Each screen is identified by its **model** (`ShellScreen.model`, e.g. `XENEON EDGE`), not by its connector: connector names such as `DP-1` / `HDMI-A-1` can change (for instance with an eGPU). The connector is still usable as a fallback (`eDP-*` for a laptop's internal panel).

A **profile** associates a screen with:

- a **mode**:
  - `normal` — permanent bar, classic layout (main monitor, laptop internal panel, any unknown screen);
  - `modules` — dashboard of modules with window slots (Xeneon);
- a **theme** (otherwise the mode's theme);
- `touch` — enlarged targets, nothing that depends on hover (no touch screen is usable today, but it is planned for);
- overrides (bar, OSD…).

## Themes

- Planned themes: **Classic** (default and base), **Constellation** (replaces Ligne, inspired by Nebula), **Façade**, **Modulaire**, **Matrix**. Specification: [`themes.md`](themes.md). Decision: start from the design proposals as they are, with Classic everywhere to begin with (normal and modules screens), and refine afterwards.
- Each theme has a **light** and a **dark** variant. Switching: manual, fixed times, or sunrise/sunset (computed locally, no network). IPC for keybinds. Configured in the settings app (end of the project); identical on all screens by default, configurable per screen later.
- Theme chosen per mode (`normal` → Classic, `modules` → Façade by default), overridable per screen profile.
- A theme = tokens (palette per variant, static fonts, radii, borders, spacing) + component **style axes** (shape of sliders, gauges, workspaces, clock…) + the **bar defaults**. No component tests a theme's name: it reads tokens and axes.
- Scope: each window carries its screen's theme (`window.theme`); components find it through `QsWindow.window`. The same component can therefore render as Classic on the main monitor and as Façade on the Xeneon.

## Bar (normal screens)

Always present. Widget layout in `left` / `center` / `right`, with configurable rendering, each theme providing its own defaults:

| Parameter | Values |
|---|---|
| `style` | `full` (one strip) · `islands` (one island per zone) |
| `floating` | detached from the edges (margin) or attached |
| `margin`, `radius`, `opacity`, `border` | numbers |
| `screenCorners` | radius of the rounded screen corners (0 = none) |

## Modules mode

- A **free grid** of slots. A slot is either a **module** (media, lyrics, monitoring, VU…) or a **window slot**.
- The **Hyprland workspaces** of this screen are **module pages**: each workspace has its own grid. Switching workspace switches page.
- A window arriving on a workspace of the modules screen is made floating and placed by the shell in a free window slot (rules pushed through `hl.dsp.window.float/move/resize`). Any Hyprland window can go there (kitty, btop…).
- Modules are drawn on the `bottom` layer, beneath windows.
- An editing interface will let the user choose, place and resize modules and window slots.

## Fullscreen

Nothing **automatic** is shown above a fullscreen game (`HyprlandWorkspace.hasFullscreen`): the OSD and notifications are redirected to a modules screen if there is one, otherwise held back. Things invoked explicitly (launcher, panels) are still allowed.

## Phases

Done: foundation (1), Classic theme tokens (2, partial), first pass of modules mode (3), EN/FR languages. Notifications (5) written and tested in a controlled trial (with Caelestia stopped for a minute); final switch-over still to be decided. Bar on all 4 edges and frame mode done (drawers merged into the frame: later, with the design). Wallpaper, lyrics/VU, two-layer config, settings app, lock and idle written (actual locking not yet tested: needs a manual test session). Current priority: **raw features**; the design gets polished afterwards.


1. **Foundation** — screen profiles by model, theme registry with schedulable light/dark, per-window theme, bar styles, fullscreen policy, touch flag.
2. **Themes** — implementation of the five themes from the design study's specification (fonts, palettes, components).
3. **Modules mode** — grid, pages per workspace, window slots, first modules (media, lyrics, monitoring, VU).
4. **Editor** — interface to manage modules and the bar; settings screen (also reachable from the launcher).
5. **Notifications** (switch-over from Caelestia), wallpaper, then idle and lock last.
