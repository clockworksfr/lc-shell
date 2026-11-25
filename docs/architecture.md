# Architecture

How lc-shell is put together, and why. The README covers installation and the user-facing settings. [`themes.md`](themes.md) and [`bar-editing.md`](bar-editing.md) go into the details of the themes and the bar.

## Configuration

`services/Config.qml` merges two JSON files. Both are watched and applied live:

- `config/defaults.json` (in the repository): generic defaults;
- `$XDG_CONFIG_HOME/lc/settings.json`: the user's settings, also written by the settings app and by IPC.

Objects merge key by key; arrays (widget lists, screens, dashboard cells) replace. Writes are atomic (temporary file + rename). A file with invalid JSON is ignored and the previous configuration stays in place, so a typo doesn't break the screen.

## Screens and profiles

Each screen gets a `ScreenScope` (`windows/ScreenScope.qml`). It resolves the screen's profile and loads the windows that screen needs: wallpaper, bar, frame, screen corners, OSD, notification popups and dashboard. It also loads the windows opened on demand: launcher, clipboard, screenshot editor and bar edit toolbar.

A **profile** is an entry of `screens`. The first one whose `match` fits wins:

- `match.model` is a substring of the screen's model (`ShellScreen.model`, e.g. `XENEON EDGE`). Models are preferred because connector names (`DP-1`, `HDMI-A-1`…) can change, for instance when an eGPU is plugged in;
- `match.name` is a glob on the connector name (`eDP-*` for a laptop's internal panel).

A profile can set:

- `theme`: the theme of that screen's bar, panels and popups;
- `touch`: larger hit targets (48 px instead of 24, 72 px on dashboards) and larger edit-mode badges;
- overrides of the per-screen defaults in `modes.normal` (`bar`, `osd`…), merged key by key. `null` or `false` disables one on that screen (`"bar": null` = no bar).

Every screen is a "normal" screen: `modes.normal` is the only mode, and a `mode` key in a profile is ignored. Dashboards are tied to workspaces, not to screens (see below).

When the bar edit mode or the settings app changes a screen's configuration, the change goes into that screen's profile. If there isn't one, it is created on the fly, matched by model.

## Themes

- There are five themes: **Classic** (default), **Constellation**, **Façade**, **Modulaire** and **Matrix**, each with a light and a dark variant. Specification: [`themes.md`](themes.md).
- `appearance.themes.normal` is the theme of bars, panels, cards and popups. `appearance.themes.modules` is the theme of dashboards. Both default to `classic`. A profile's `theme` overrides both for that screen, and its `variant` (`dark` / `light`) overrides the global light/dark setting there.
- `appearance.variant` is `dark`, `light` or `auto`. With `auto`, `appearance.schedule` switches at fixed times or at sunrise/sunset. Sun times are computed locally by `theme/Sun.qml`, with no network.
- A theme definition (`theme/defs/<Theme>.qml`) only lists what it changes; `Themes.resolve()` deep-merges it over `theme/defs/Base.qml`. A resolved theme holds:
  - tokens: `color`, `font`, `space`, `radius`, `border`, `motion`, `drawer`, `hit`;
  - the bar defaults (`bar`);
  - component **style axes** (`style`): workspaces indicator, covers, rings, displays, module frames, app icons…
- **No component tests a theme's id**: components only read tokens and style axes, so adding a theme only takes a new definition file.
- **Per-window scope**: each window carries its screen's theme (`window.theme`), and components find it through `QsWindow.window`. The same component can therefore render as Classic on one screen and as Façade on another. Surfaces that aren't Quickshell windows (the session lock) use `Themes.fallback`, which is the `normal` theme.

## Bar

A screen has at most one bar, on any edge (`position`: `top`, `bottom`, `left`, `right`).

- **Zones**: widgets go in three zones, `left`, `center` and `right` (top, middle and bottom on a vertical bar). A zone holds one group, or several as a list of lists.
- **Look**: it comes from the theme's `bar` defaults and can be overridden in the bar config:
  - `style`: `full` (one band) or `islands` (one background per group);
  - `floating`, `margin`, `radius`, `opacity`, `border`, `padding`, `spacing`;
  - `height` and `verticalWidth` (thickness of a horizontal or vertical bar);
  - `length`: 0 = full length; otherwise a centred bar of that many pixels, or that share of the edge when below 1;
  - `screenCorners`.
- **Frame** (`bar.frame`): a ring around the desktop, with the bar as its thick side.
  - It is drawn on the `bottom` layer, under windows and above the wallpaper.
  - The other sides reserve their space with invisible `FrameEdge` surfaces.
  - In a frame the bar is docked: no islands, no floating, no fixed length.
- **Hover cards and panels** are layer-shell surfaces, not Quickshell popups. A popup cannot move while shown and only shows while its bar has the pointer, which would break panels opened from a keybind. Both come out of the bar as a **drawer** merged with the widget's island (see [`themes.md`](themes.md#drawers)).
- **Edit mode** rearranges widgets in place: see [`bar-editing.md`](bar-editing.md).

## Dashboards

- **Contents**: a dashboard is a grid of **modules** and **window cells**, drawn on the `bottom` layer, under windows. Modules: clock, weather, media, lyrics, system, network, VU, quick settings, Hue, workspaces, theme switch.
- **Presets and workspaces**: dashboards are saved as **presets** (`dashboards.presets`) and bound to **workspaces** (`dashboards.workspaces`: workspace name → preset).
  - When a workspace bound to a preset is active, its screen shows that dashboard, whatever the screen.
  - Switching workspace switches dashboard. A workspace without a preset has no dashboard.
- **Grid**: it holds as many cells of about `cellWidth × cellHeight` as fit in the room the bar leaves (12 × 4 on a 2560 × 720 screen, 24 × 12 on 5120 × 2160). A preset can override the grid. A cell made on a bigger screen is pulled back inside.
- **Window cells** (`dashboard/CellTiler.qml`):
  - a window opening on such a workspace is floated, resized and moved into the first free `window` cell, through `hl.dsp.window.*` dispatchers;
  - it keeps its cell while it stays on that workspace, and extra windows stack in the last cell;
  - a window that leaves is put back into tiling;
  - fullscreen windows are left alone;
  - `dashboards.windows.ignore` / `only` filter windows by class.
- **Module layouts**: modules adapt to their size, from a single cell up to large and "poster" layouts. They are edited with the dashboard editor or in Settings › Dashboard.

## Fullscreen policy

Nothing **automatic** is ever drawn over a fullscreen window:

- A screen counts as fullscreen when a window on its active workspace is in Hyprland's real fullscreen state (fullscreen state bit 2). A maximised window (bit 1) also sets Hyprland's `hasFullscreen` flag, but it doesn't count: the shell keeps showing over it.
- On such a screen, the frame, the screen corners, the OSD and notification popups are unloaded, and every animation duration drops to 0.
- The OSD and notification popups go to another screen instead: preferably one showing a dashboard, otherwise any screen without a fullscreen window. If there is none, they are held back.
- Things the user opens explicitly (launcher, clipboard, panels, dashboard editor) are still allowed.

While a screen is being shared or recorded (Hyprland `screencast` event), window titles are hidden in the bar and in the window card.

## Animations

`theme/Motion.qml` applies the theme's `motion` tokens: fast / base / slow durations, entry easing and overshoot, stagger.

- **Exits** use `InCubic` at 0.75 × the duration and always start from the current value, so they can be interrupted.
- **Reduced motion** (`appearance.reducedMotion`, which defaults to GNOME's `enable-animations`): durations are capped at 90 ms and nothing moves, it only fades.

Details in [`themes.md`](themes.md#animations).
