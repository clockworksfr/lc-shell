# Bar: editing and hover cards

How the bar's layout is stored, how edit mode changes it, and how hover cards behave. Logic: `services/BarEditor.qml`; surfaces: `windows/bar/` (`Bar.qml`, `BarZone.qml`, `EditToolbar.qml`, `EditToast.qml`, `HoverCard.qml`); card contents: `cards/`.

## Data model

- **Zones**: `left`, `center` and `right`, laid out along the bar (on a vertical bar: top, middle, bottom). `start` and `end` are accepted as aliases of `left` and `right`.
- **Groups**: a zone is a list of entries (one group) or a list of lists (several groups). A group is an island in the `islands` style, or a run of widgets separated from the next group by a gap in the `full` style.
- **Widget entries**:
  - an entry is a widget name (`"clock"`) or an object with a `type` and options (`{ "type": "clock", "format": "HH:mm" }`);
  - `size` is `compact`, `normal` (the default, then left out) or `extended`;
  - order is array order;
  - names map to files in `widgets/Registry.qml`; an unknown name shows as `?name` in red.
- **Widget types**: `workspaces`, `window`, `clock`, `media`, `volume`, `network`, `wifi`, `bluetooth`, `battery`, `system`, `weather`, `notifications`, `tray`, `quickSettings`, `lights`, `modes`, `dynamicIsland`.
- **Vertical bars**: widgets switch to a compact form: the clock stacks hours over minutes (`verticalFormat`), the media widget shows its state glyph only, and the tray becomes a column. Text widgets show `extended` as `normal`.
- **Saving** ("Done"): each edited screen's zones are written into that screen's profile (`screens[].bar`), and a profile matched by model is created if needed. A zone equal to the default (`modes.normal.bar`) is not copied, so later changes to the default still apply to it. The settings file is written atomically and reloaded live like any other change.

## Edit mode

- **Entry**: edit mode applies to every bar at once, and hover cards are disabled while it is on. Ways to enter it:
  - right-click an empty spot of the bar → menu (“Edit the bar”, “Bar settings”, “Settings”);
  - right-click a widget → its menu: the widget's own actions, “Open” when it has a panel, “Edit this widget”, “Remove from the bar”;
  - a 600 ms long press on a widget (finger or held mouse button) enters edit mode with that widget selected;
  - the `lc:editBar` global shortcut (toggles edit mode), Settings › Bar, or IPC `bar edit`.
- **Display**:
  - each zone is tinted and outlined, and ends with a “+” target that starts a new group (island);
  - each widget is outlined, with an S/M/L size badge at the bottom right (click to cycle) and a remove cross at the top left. Being on opposite corners, the badges of neighbouring widgets never meet. Both are larger on touch screens;
  - widgets that normally hide themselves (nothing to show) appear dimmed.
- **Drag**:
  - the dragged widget follows the pointer as a lifted label (scale 1.05, rotation −1.5°, opacity 0.92) and its original stays at 35% opacity;
  - an accent insertion cursor shows where it will land: in the zone under the pointer, otherwise the nearest one along the bar;
  - dropping on a zone's “+” starts a new group.
- **Toolbar** (`EditToolbar.qml`, next to the bar of each screen):
  - actions: Undo, Redo, Discard, Done;
  - with no selection, a hint; with a selected widget, its inspector: its three sizes as live previews, its zone, “To <screen>” for each other screen with a bar (undone in one step), and “Remove”;
  - a palette of the widgets not on this bar, with previews and a search field (“Find a widget…”). A click adds the widget to the selected widget's zone, otherwise to the end of the bar.
- **Keyboard** (the toolbar holds the keyboard while editing):
  - Esc = done (changes kept);
  - `Ctrl+Z` / `Ctrl+Shift+Z` = undo / redo;
  - Delete removes the selected widget.
- **Undo**: the last 50 layouts; “Discard” drops every change made since entering edit mode.
  - After “Done”, a “Bar saved · Undo” toast stays for 8 s on the focused screen (with a timer bar, paused on hover).
  - Its “Undo” puts the bars back as they were before saving.
- **Frame**: a framed bar has no islands; its widgets go on the bar side only.
- **IPC**:
  - `bar edit`, `bar done`, `bar discard`;
  - `bar select <type>`: select a widget on the focused screen's bar;
  - `bar resize <compact|normal|extended>`: resize the selection;
  - `bar undoSave`: same as the toast's Undo.

## Hover cards

### Behaviour

- **Opening**: after 350 ms without moving over a widget, its card slides out of the bar as a drawer.
  - While a card is open, or was closed less than 600 ms ago, another widget's card shows without delay.
  - The drawer **does not close** in between: it slides and resizes to the new widget (theme `base` duration) while the content cross-fades.
- **Closing**: when the pointer leaves, the card stays for 250 ms (time to reach it) and then slides back into the bar; the pointer on the card keeps it open.
- **Click**: clicking a widget either **pins** its card or opens the widget's panel, depending on the widget:
  - clock, volume, network, Wi-Fi, Bluetooth and modes pin their card;
  - battery, quick settings, lights and notifications toggle a panel;
  - some widgets act directly: media plays / pauses, workspaces focus the clicked workspace, and system runs `system.monitorCommand` (`kitty -e btop` by default).

  A pinned card stays open until a click outside, Esc, or another click on the widget, and takes the keyboard when needed. Opening a widget's panel closes its card.
- **Surface**: one card surface per bar, a layer surface running along the bar's side.
  - Its input region is limited to the drawer.
  - It stays mapped while closed, with nothing drawn and no input, and only ever grows. Resizing it as the card opens would show a stretched frame from the compositor.
  - A card's content stays loaded between openings of the same type.
- **Size and placement**:
  - 380 px wide, at most 60% of the screen height;
  - centred on the widget and kept 8 px from the screen edges;
  - it comes out of whichever edge the bar is on.
- **Joint with the bar**: the card is a merged drawer, joined to the bar by concave fillets (`drawer.fillet`: Classic 10, Constellation 14, Matrix 12). Façade and Modulaire hang it straight, without fillets; Modulaire's card is an aluminium plate with four screws. See [`themes.md`](themes.md#drawers).
- **Disabled** in edit mode.
- **IPC**: `bar showCard <type>`, `bar showCardOn <type> <screen>`, `bar hideCard`, `bar card` (state).

### Cards

| Card | Contents |
|---|---|
| **Workspaces** | Active workspace of this screen: window count and a schematic of its windows at the screen's proportions (focused window outlined); then the screen's other workspaces. |
| **Clock** | Date and week number, time with seconds, month calendar; arrows or the scroll wheel for other months, a click on the month goes back to today. |
| **Media** | The theme's cover (84 px) beside the source, title and “Artist · Album”; seekable progress with times; three lines of lyrics (inside the theme's display in Façade and Modulaire); previous / play / next; one chip per player. |
| **Volume** | Volume, outputs, per-application volumes, input (live level meter, devices). |
| **Network** | Connection, live download/upload with a 60 s graph, local address. |
| **Wi-Fi** | Power, the 4 strongest networks; joining a known or open network takes one click (a new secured network: Settings › Network, for its password). |
| **Bluetooth** | Power, devices (connected first, with battery), connect or disconnect in one click; search and pair new devices. |
| **Battery** | Level, state, time left, 6 h history, power profile. |
| **Notifications** | Count, Do Not Disturb, the 3 latest (grouped by app), “Clear all”. |
| **Tray** | For the hovered icon: icon, name, status, tooltip, the first actions of its menu as chips, “Open” and “Menu”. Opened without a hovered icon (IPC): every item, one line each. |
| **System** | CPU and GPU (load, temperature, last minute), memory, the 3 busiest processes. Read-only (the widget opens the system monitor). |
| **Weather** | Large temperature, condition, feels-like, wind; next 6 hours with chance of rain; place, source and time of the reading (with its date when old). |
| **Active window** | App, workspace and screen, full title, the app's other windows (click to go there), actions (float, fullscreen, pin, move to a workspace, close; close asks for a second click). Titles are hidden while the screen is shared. |
| **Modes** | Caffeine and Do Not Disturb (a switch each, with durations under the active one), presentation (both at once). |
| **Dynamic island** | The media card while something plays, otherwise the clock card. |

### Per-theme rendering

Cards are drawn with the theme's components:

| Theme | Progress | Large figures | Small labels |
|---|---|---|---|
| Classic | pill | Figtree 700 | as written |
| Constellation | comet (2 px line, glowing head) | Outfit 300 | as written |
| Façade | bar-graph cells, unlit ones as ghosts | DSEG7 Classic, italic, glowing, unlit “88:88” segments behind | uppercase |
| Modulaire | LED ladder (green, yellow, red) | Nixie One, orange, glowing | uppercase |
| Matrix | 5 px dots | Doto Matrix | uppercase |

## Notes on some widgets

- `system`: CPU (compact), + GPU (normal), + temperatures and RAM (extended); red when CPU or GPU load goes above 90%. Click runs `system.monitorCommand` (default `kitty -e btop`).
- `dynamicIsland`: the most important current activity, otherwise the time: screen sharing (red), microphone in use by an app, track playing (click = play / pause). Its card follows suit.
- `tray`: one card per hovered icon.
