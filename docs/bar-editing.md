# Bar: editing and hover cards (study v4)

Specification derived from the design study (mockups “lc-shell renders”, Edit and Hover tabs). To be adapted to the existing config model (screen profiles in `screens[]`, per-mode config) rather than to the `bar.screens` structure proposed by the study.

## Data model

- Zones `start`, `center`, `end` (vertical: top, middle, bottom).
- A zone = a list of **groups**; a group = an island (islands layout) or a capsule / a separator (full bar, frame).
- Widget: `{ id, type, size, options }`; stable `id` (type + counter); `size` = `compact` | `normal` | `extended`. Order = array order.
- Types: `workspaces`, `window`, `clock`, `media`, `volume`, `network`, `bluetooth`, `battery`, `notifications`, `tray`, `system`, `weather`, `dynamicIsland`.
- Vertical: `window` forced to compact; `media`, `notifications`, `clock` capped at `normal` (refused size → next allowed size).
- Widget sent to a modules screen: becomes a module (S = 2×1, M = 4×2, L = 6×3) in the first free slot.
- Written on “Done”, atomically (temporary file + rename); the config is still hot-reloaded.
- Compatibility: a widget written as a plain string (`"clock"`) is still accepted.

## Edit mode

- **Entry**: right-click on the bar → menu (“Edit the bar”, “Bar settings”, “Settings”); 600 ms long press on a widget (touch); shortcut (proposed: `Super + Alt + E`); Settings › Bar; IPC `bar edit`. All bars enter edit mode; hover cards are disabled.
- **Display**: zones with a dotted accent outline at 55% + accent background at 7% + 10 px mono label; each widget has a ⋮⋮ handle, an S/M/L badge and a close cross (20 px, 48 for touch); a floating toolbar under the bar of the active screen: Undo, Redo, Palette, Theme values, Discard, Done, screen thumbnails.
- **Drag**: 4 px threshold (mouse), 300 ms press (touch); lifted widget at scale 1.05, rotation −1.5°, opacity 0.92, 35% ghost left in its place; 3 px accent insertion caret, neighbours moving apart in 160 ms; insertion before the first widget whose midpoint is past the pointer.
- **Targets**: between widgets, start/end of a zone, “+ New island” / “+ Group”, palette (= remove), screen thumbnail (= move to that screen; no dragging between layer-shell surfaces); a refused target gets a red outline with the reason.
- **Size**: S → M → L badge (bottom right of the widget, the cross at top left: never overlapping between neighbours; 28 px on a touch screen); `+` / `−`.
- **Inspector** (click; bottom sheet on touch): sizes with preview, widget options, “Move to…”, “Remove”.
- **Palette**: missing widgets, preview, search; drag to a zone, or “+” then the zone.
- **Undo**: 50 snapshots, `Ctrl+Z` / `Ctrl+Shift+Z`; “Discard” restores the state on entry; after “Done”, an “Undo” toast for 8 s.
- **Exit**: Done, Esc, click outside the bar and toolbar (changes kept); a fullscreen window starting closes edit mode and saves.
- **Keyboard**: Tab selects a widget; ← / → move it (and change zone at the end of a zone); Delete removes; Enter opens the inspector.
- **Frame**: widgets only on the bar side.

## Hover cards

### Common rules

- Appears after 350 ms without movement: the drawer slides out of the bar. With a card open (or closed less than 600 ms ago), another widget's card shows without delay and the drawer **does not close**: it slides and resizes to the new widget (theme `base` duration) while the content cross-fades. Persistent layer-shell surface along the bar, input limited to the drawer. Exit: 250 ms grace period, then a 120 ms fade; the pointer over the card keeps it open.
- Click: the card grows into the full panel (220 ms). Touch: 1st tap = card, 2nd tap / “Open” = panel, long press = edit mode. Keyboard: focus = card, Enter = panel, Esc = close. The card's controls work without opening the panel.
- Never in fullscreen, in edit mode, or during a drag.
- 380 px wide (360 on a laptop), ≤ 60% of the screen height; inner padding 16, gap 12.
- Placement: below the bar (top), above it with sections reversed (bottom), beside it and vertically centred (left/right), merged drawer (frame); kept 8 px from the edges.
- Attachment per theme: Classic 8 px gap, radius 20; Constellation 64×12 neck, radius 24; Façade hanging card, square top corners; Modulaire screwed-on panel; Matrix 8 px, 1 px outline, radius 28.

### Cards

1. **Workspaces** (Hyprland workspaces + clients): “Workspace N”, screen, window count; schematic preview with the screen's proportions (rectangles with icon and title, focused window outlined); workspace thumbnails; “click: go there · drag a window here”.
2. **Clock and calendar** (time, iCal/CalDAV agenda, optional second time zone): long date + week number, chip for the second time zone; large time, dimmed seconds; mini month (week-number column, tinted current week, filled current day, event dots); next two events; scroll wheel = month.
3. **Media** (MPRIS, cached lyrics): 84 px cover, source “1/3”, title, artist, album; clickable progress with elapsed/remaining time; three lines of lyrics; previous / play (64 px) / next; source chips.
4. **Volume** (PipeWire): output, 28 px slider with value; apps with mini bars; microphone with live level; output chips; scroll wheel ±2%, middle click = mute.
5. **Network** (NetworkManager, `/sys/class/net` counters over 60 s, VPN): signal (dBm, band, channel); download/upload modules with a graph; local IP, gateway latency; VPN; offline: last network + “Retry”.
6. **Bluetooth** (BlueZ, UPower): one row per device (battery ring, name, %, remaining time, “low” < 20%, “Connect” if disconnected).
7. **Battery** (UPower, power-profiles-daemon): large %, state, remaining time; 6 h graph + dotted projection + “now” marker; profiles; health, cycles.
8. **Notifications**: title + badge + do-not-disturb toggle; last 3, grouped “×n”; “Clear all”; swipe to dismiss.
9. **Tray** (StatusNotifierItem): icon, name, status, tooltip, menu action chips; click = open, right-click = menu.
10. **System** (`/proc`, amdgpu sysfs/hwmon, without waking the eGPU): CPU / GPU modules (value, temperature, 60 s graph); RAM and VRAM bars; top 3 processes; fans; click = btop.
11. **Weather** (open-meteo, cached): large figure, condition, feels-like, wind; next 6 hours + chance of rain; source and time of the reading; offline: last data with its timestamp.

12. **Active window** (Hyprland toplevels): icon, app, workspace and screen; full title; the app's other windows (click: go there); actions Floating, Fullscreen, Pin, Close (second click to confirm); “Move to” a workspace. During screen sharing (Hyprland `screencast` event), titles are hidden in the bar and the card.

### Per-theme variants

| Theme | Progress | Large figures | Labels |
|---|---|---|---|
| Classic | pill | Figtree 700 | JetBrains Mono uppercase |
| Constellation | comet (2 px + head) | Outfit 200–300 | Outfit, letter-spaced |
| Façade | VFD / LCD segments | Doto in a display | Plex Condensed |
| Modulaire | LED ladder | Nixie | Michroma |
| Matrix | 6 px dots | Doto Matrix | Space Mono uppercase |

## Implemented (design 5)

- Toolbar (`windows/bar/EditToolbar.qml`): actions (undo, redo, discard, done); inspector for the selected widget with its three sizes as live previews, the zone, “To <screen>” (other normal screens with a bar; undoable in one step) and “Remove”; palette of missing widgets with preview and search.
- After “Done”: “Bar saved · Undo” toast for 8 s (`EditToast.qml`, timer bar, paused on hover); “Undo” restores the bars as they were before saving.
- IPC: `bar select <type>`, `bar resize <compact|normal|extended>`, `bar undoSave`.
- Not yet: lifted widget (scale, rotation), refused target with its reason, sending to a modules screen (as a module), frame hatching, bottom sheet on touch.

## Added widgets

- `system`: CPU (compact), + GPU (normal), + temperatures and RAM (extended); red above 90%; click = `system.monitorCommand` (default `kitty -e btop`). Card: CPU and GPU (load, temperature, last minute), memory, top 3 processes.
- `dynamicIsland`: the most important activity, otherwise the time — screen sharing (red), microphone in use by an app, track playing (click = play / pause). Its card follows suit: the media card during playback, otherwise the clock card.
- Tray: one card per hovered icon (name, status, tooltip, first menu actions as chips, “Open”, “Menu”); with no icon hovered, the list of all of them.
