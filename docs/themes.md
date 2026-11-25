# Themes

lc-shell has five themes: **Classic**, **Constellation**, **Façade**, **Modulaire** and **Matrix**. Each one is a full design language (fonts, shapes, bar, component styles, motion), not just a palette, and each has a light and a dark variant.

A theme is a definition file in `theme/defs/` that only lists what differs from `theme/defs/Base.qml`; `Themes.resolve()` deep-merges the two. Components never test a theme's id: they read tokens and **style axes**, so the differences below are all data. See [`architecture.md`](architecture.md#themes) for how themes are chosen per screen and for dashboards.

Colours below are written as in the definitions: `#RRGGBB`, or `#AARRGGBB` (Qt's order, alpha first) for translucent ones.

## Common rules

- **Colour roles**: `bg` (desktop background), `surface`, `surface2`, `surface3`, `ink`, `soft` (dimmed ink), `line`, `accent`, `accent2` (second accent: gradients, comets), `onAccent`, `urgent`, `warn`, `ok`, plus `glass`, `star`, `glow` (glow of large figures; transparent = none) and `ghost` (unlit segments behind figures). Some themes add their own roles (`silk`, `nixie`, `lcd`, `signal`…).
- **Hit targets** (`hit`): 24 px with a pointer, 48 px on touch screens, 72 px on touch dashboards.
- **Fonts**: bundled static files only (`assets/fonts`, registered by `theme/Fonts.qml`), since Qt ignores the axes of variable fonts. Variable fonts are instantiated with `tools/instance-font.py`, e.g. Doto → “Doto Matrix” and “Doto LCD”.
- **Icons**: one icon font for every theme, a subset of Material Symbols Rounded (outlined and filled), built by `tools/gen-icons.py`.
- **Wallpaper**: each theme ships a light and a dark tiled wallpaper (`assets/wallpapers`), shown when no image is chosen (`wallpaper.themeDefaults`).
- **Fullscreen**: on a screen showing a fullscreen window, nothing automatic is drawn and all animations take 0 ms.

## Bar settings

Theme defaults, overridable in the bar config of `modes.normal` or of a screen profile:

| Key | Values | Base default |
|---|---|---|
| `position` | `top` · `bottom` · `left` · `right` | `top` |
| `style` | `full` (one band) · `islands` (one background per group) | `full` |
| `floating` | detached from the screen edges by `margin` | `false` |
| `margin` | px | 0 |
| `radius` | px | 0 |
| `opacity` | background opacity, 0–1 (content stays opaque) | 1 |
| `border` | px, colour `line` | 0 |
| `padding`, `spacing` | px, inside the band or each island / between widgets | 8, 18 |
| `height` | thickness of a horizontal bar, px | 32 |
| `verticalWidth` | thickness of a vertical bar, px | 48 |
| `length` | 0 = full length; px, or a share of the edge below 1 (centred bar) | 0 |
| `screenCorners` | radius of the rounded screen corners, 0 = none | 0 |
| `frame` | see [Frame](#frame) | off |

Theme-only keys: `caseColor` (a case colour instead of `surface`), `rails` (perforated rails along the long edges) and `plates` (each group on its own plate).

## Style axes

| Axis | Values |
|---|---|
| `workspaces` | `labels` (numbers) · `dots` (active = a pill, lying on a horizontal bar, standing on a vertical one) · `stars` (dots, active = four-pointed star) · `segments` (a VFD window, one 7-segment digit per workspace) · `sequencer` (one step per workspace: a round LED and its number) · `numbered` (a dot and its number per workspace, empty ones in between shown dim) |
| `module` | frame of dashboard modules: `classic` · `constellation` · `facade` · `modulaire` · `matrix` |
| `cover` | album art: `square` (rounded) · `sphere` (round planet with a halo) · `disc` (round, turning while playing, ringed with dots following the sound) · `inset` (square, recessed in a black frame) · `screwed` (square, 3 px corners) · `none` |
| `ring` | round gauges: `arc` (thick 270° arc) · `orbit` (thin circle, gradient arc, a planet at the value) · `knob` (rotary knob, cream index) · `dots` (36 dots, the lit ones glowing) · `vu` (a VU dial for audio, else `arc`) |
| `display` | display windows inside modules: `none` · `vfd` (black glass, static scan lines, phosphor ink) · `lcd` (green or amber LCD, dark ink) |
| `appIcons` | `native` · `tinted` · `mono` (see [App icons](#app-icons)) |
| `labelCase` | `none` · `upper` (small labels) |
| `statusIcons` | status widgets as icon + value (`true`) or as text |
| `statusSigil` | text statuses as one-line mono sigils (“BT 2”, “NET ↓1,3M”): `phosphor` (VFD ink, dimmed when off) · `led` (a status LED before the text) |
| `statusStack` | text statuses as a small soft label over the value (“VOL / 64”) |
| `barClock` | `display`: the bar's clock in the display font |
| `glass` | a glass highlight over the top of islands and panels |
| `ghostDigits` | unlit segments (“88:88”) behind large figures |
| `scanlines`, `screws`, `brushed` | VFD scan lines, screws on module plates, brushed aluminium |

## 1. Classic (default)

Clean and neutral: soft rounded shapes, a jade accent, floating islands.

| Role | Dark | Light |
|---|---|---|
| bg | #0F1114 | #E7EAEE |
| surface | #171A1E | #FAFBFC |
| surface2 | #20242A | #EEF1F4 |
| surface3 | #2B3037 | #E1E5EA |
| ink | #E9ECEF | #14171B |
| soft | #A1A9B3 | #56606B |
| line | #2B3038 | #D5DAE1 |
| accent, accent2 (jade) | #5FD0A8 | #0E7A5C |
| onAccent | #06281D | #FFFFFF |
| urgent | #FF6B5E | #C8372D |
| warn | #F2C14E | #9A6A00 |
| ok | #8BD17C | #2E7D3A |

- **Fonts**: Figtree (text and figures, 700 for large figures) · JetBrains Mono. Sizes 12 / 14 / 17 / 28.
- **Shapes**: radii control 10, tile 16, panel 20, card 28; 1 px borders; spacing 4 / 8 / 12 / 16 / 24 / 32.
- **Bar**: floating islands, margin 8, height 40 (vertical 56), radius 14, opacity 0.94, border 1, padding 14, spacing 18, screen corners 14.
- **Components**: workspaces as dots (active = accent pill); classic module cards; square rounded covers; thick arc gauges; pill progress bars; round buttons (accent when primary); quick-settings tiles with the icon on top and an accent fill when on; native app icons.

## 2. Constellation

Space mood: floating islands of tinted glass (no blur), stars, comets and orbits. The concept is inspired by [Nebula](https://github.com/LilaccFlowerr/Nebula) (AGPL-3.0; concept only, no code taken): floating islands with fixed roles and drawers joined to their island by concave fillets. It differs by a fixed palette, constellations, comets and orbits, and Outfit instead of Inter. The dark variant is “night”, the light one “dawn”.

| Role | Night (dark) | Dawn (light) |
|---|---|---|
| bg | #0B0E1A | #EEF0F8 |
| surface | #141A2B | #FFFFFF |
| surface2 | #1C2338 | #F3F4FB |
| surface3 | #262E47 | #E4E7F4 |
| ink | #E6E9F5 | #171B2E |
| soft | #9AA3BF | #5A6180 |
| line | #2A3350 | #D8DCEC |
| accent | #9FB8FF | #4255C8 |
| accent2 | #F2A7D8 | #C2408F |
| onAccent | #0E1430 | #FFFFFF |
| urgent | #FF7A8A | #C93A4E |
| warn | #FFD27A | #956400 |
| ok | #7EE0B5 | #23805B |
| glass (top highlight) | #14FFFFFF | #99FFFFFF |
| star | #B0FFFFFF | #8A3A4680 |

- **Fonts**: Outfit (300 for large figures, slightly widened: `heroScale` 1.04) · Geist Mono. Sizes 12 / 14 / 17 / 28.
- **Shapes**: radii control 16, tile 22, panel 24, card 24; 1 px borders; spacing 6 / 10 / 14 / 20 / 28 / 36; drawer fillet 14.
- **Bar**: floating islands, margin 10, height 44 (vertical 52), radius 22, opacity 0.86, border 1, padding 16, spacing 20, screen corners 18. Frame off by default (thickness 8, inner radius 22).
- **Components**:
  - workspaces as a constellation of dots, with a four-pointed accent star for the active one;
  - glass module panels (gradient, accent-tinted edge) and a glass highlight on islands and panels;
  - round “sphere” covers with a halo;
  - orbit gauges (a planet at the value);
  - comet progress (2 px line, glowing head);
  - round buttons with a gradient, quick-settings tiles with an `accent` → `accent2` gradient when on;
  - thin glowing spectrum lines;
  - app icons tinted with the accent.

## 3. Façade

A hi-fi amplifier front panel: metal case, condensed silk-screened labels, a VFD display with cyan phosphor that glows in the dark variant, and a grey-green LCD in the light one.

| Role | Dark (VFD) | Light (LCD) |
|---|---|---|
| bg | #0D1112 | #C9CCC6 |
| surface (faceplate) | #1B1E20 | #D7D8D5 |
| surface2 (glass / LCD) | #030505 | #B6BEA1 |
| surface3 | #2B2F31 | #C3C5C0 |
| ink (phosphor / segments) | #6EF3D6 | #1D2618 |
| soft | #996EF3D6 | #A61D2618 |
| ghost (unlit segments) | #1A6EF3D6 | #141D2618 |
| silk (silk-screen) | #C9CCC4 | #1E2022 |
| line | #000000 | #8F9295 |
| accent | #6EF3D6 | #1D2618 |
| accent2 | #F1DFAE | #1E2022 |
| onAccent | #030505 | #FFFFFF |
| urgent | #FF4A3D | #C8392C |
| warn (amber) | #FFB547 | #A85A00 |
| ok | #6EF3D6 | #2E7D3A |
| glow | #8C6EF3D6 | transparent |

Extra roles: `screen` / `screenEdge` (display windows), `caseTop` / `caseMid` / `caseBottom` / `caseEdge` / `caseFlat` (the bar's metal case gradient and edge, the frame's thin sides), `plate` (zone plates), and `card`, `cardBlock`, `cardBubble`, `cardInk`, `cardSoft` (hover cards, which use silk text on their own surfaces while keeping the VFD ink for displays, progress and sliders).

- **Fonts**: IBM Plex Sans Condensed · IBM Plex Mono · DSEG7 Classic, bold italic, for large figures (narrowed: `heroScale` 0.74) · DSEG14 Classic for text inside displays and for lyrics, in uppercase. Sizes 12 / 14 / 17 / 28.
- **Shapes**: radii control 8, tile / panel / card 6; 2 px borders; cards hang straight under the bar (drawer fillet 0).
- **Bar**: a centred front panel covering 66% of the edge (`length` 0.66), docked, height 44 (vertical 64), radius 6 on the corners away from the edge, opaque, border 2, padding 16, spacing 13, no screen corners. The case is a metal gradient with a black edge and a light top bevel, and each group sits on its own plate.
- **Components**:
  - the bar clock in DSEG7;
  - workspaces as 7-segment digits in a VFD window, after a silk-screened label (active lit, occupied dim, empty unlit, urgent amber);
  - statuses as phosphor sigils, dimmed to the ghost colour when off;
  - large figures with unlit “88:88” segments behind them and a phosphor glow;
  - VFD display windows with static scan lines;
  - module frames as front panels (metal gradient, bevels, four flat screws, silk title);
  - “inset” covers in a recessed black frame;
  - bar-graph gauges (unlit cells as ghosts);
  - a cream VU dial with a damped needle (about 0.25 s) and a red zone from 0 to +3 dB;
  - segmented spectrum columns;
  - hardware keys with a LED as buttons and quick-settings tiles (amber LED when on);
  - app icons tinted.

## 4. Modulaire

A Eurorack synth: brushed aluminium plates screwed into a dark rack case, orange Nixie numerals with a halo, LEDs, small LCD windows, Michroma labels.

| Role | Dark (black anodised) | Light (aluminium) |
|---|---|---|
| bg | #141617 | #D6D3CC |
| surface → surface2 (panel gradient) | #2B2C2E → #1D1E20 | #D3D0C8 → #BCB8AE |
| surface3 | #111212 | #A9A59A |
| ink (silk-screen) | #E9E7E1 | #18181A |
| soft | #A9A69E | #4E4C47 |
| line | #14FFFFFF | #40000000 |
| ghost | #1AFF8A2A | #14C95E1A |
| accent (audio) | #E8742A | #C95E1A |
| accent2 (network) | #5AA0FF | #2F6FB5 |
| onAccent | #111212 | #FFFFFF |
| urgent | #D2332B | #B82A23 |
| warn (system) | #E5C230 | #8A7210 |
| ok (LED) | #46C46A | #2E8F4C |
| nixie | #FF8A2A | #E8742A |
| glow | #EEFF8A2A | #AAFF8A2A |
| glass | #0DFFFFFF | #40FFFFFF |

Both variants: green LCD `lcdInk` #C6F37A on `lcd` #1A2410, amber LCD `lcdAmberInk` #FFB35A on `lcdAmber` #2A1606.

- **Fonts**: Barlow Condensed · Michroma (mono role) · Nixie One for large figures, in `nixie` orange with a glow · Doto LCD for LCD windows and lyrics, in uppercase. Sizes 13 / 15 / 18 / 30.
- **Shapes**: radii control 8, tile / panel / card 3; 1 px borders; cards hang straight under their plate (drawer fillet 0), as an aluminium plate with four flat screws.
- **Bar**: a centred rack case covering 66% of the edge (`length` 0.66), docked, height 56 (vertical 72), radius 0, opaque, no border, padding 14, spacing 17, no screen corners. The case colour is #141515, with two perforated, brushed rails along the long edges (6 px, holes every 20 px) and each group on its own aluminium plate.
- **Components**:
  - the bar clock in Nixie One;
  - workspaces as a 9-step sequencer: a round LED per workspace (active orange, urgent red, occupied dim amber, empty brown) and its number in Barlow Condensed;
  - statuses as a LED (on / off / alert) followed by a silk-screened sigil;
  - LCD windows (the media widget in an amber LCD);
  - module frames as aluminium plates with four flat screws, a sheen and a centred silk title;
  - square covers with 3 px corners;
  - rotary-knob gauges and LED ladders (green, yellow from 70%, red from 85%);
  - an oscilloscope spectrum on a dark CRT;
  - square keys (orange when primary);
  - quick settings as vertical levers (up = on) under a green LED;
  - native app icons.

## 5. Matrix

Monochrome with dot-matrix numerals and a single red signal colour, in the spirit of Nothing's design. This is the author's own design language.

| Role | Dark | Light |
|---|---|---|
| bg (dot-grid background) | #080808 | #E4E4E2 |
| surface | #0B0B0B | #F2F2F0 |
| surface2 | #121212 | #FFFFFF |
| surface3 | #1A1A1A | #ECECEA |
| ink | #F2F2F2 | #111111 |
| soft | #8C8C8C | #7A7A78 |
| line | #262626 | #DCDCD9 |
| accent (= ink) | #F2F2F2 | #111111 |
| accent2 | #8C8C8C | #7A7A78 |
| onAccent | #0B0B0B | #F2F2F0 |
| urgent | #E5323A | #D71921 |
| warn | #A6A6A6 | #5C5C5A |
| ok | #8FCB9F | #3E7D52 |
| signal (red touches) | #E5323A | #D71921 |
| glow (dot figures) | #B3F2F2F2 | transparent |

Ink is the accent; red is kept for alerts and a few `signal` touches (today, the active workspace, play, progress head, slider handle).

- **Fonts**: Space Grotesk · Space Mono · Doto Matrix (static Doto, round dots) for large figures (`heroScale` 0.8) and lyrics. Base sizes.
- **Shapes**: pill-shaped controls (radius 999); tiles, panels and cards radius 28; 1 px outlines; drawer fillet 12.
- **Bar**: full and docked, height 40 (vertical 56), opaque, no border, spacing 22, screen corners 32. **Frame on** by default (thickness 10, inner radius 24, no outline).
- **Components**:
  - small labels in uppercase;
  - statuses as micro stacks, a small soft label over the value (“VOL / 64”), with no icons;
  - the bar clock alone, in Doto Matrix;
  - workspaces as dots with their number (empty ones in between dimmed);
  - module cards on a dot grid;
  - “disc” covers turning while playing;
  - gauges as rings of 36 dots;
  - 5 px dotted progress;
  - outlined pill buttons (filled with ink when primary), pill-shaped quick-settings tiles that fill with ink when on;
  - spectrum as columns of dots;
  - glow on dot figures in the dark variant only;
  - monochrome app icons.

## Frame

`bar.frame` draws a ring around the desktop, the bar being its thick side.

| Key | Values | Base default |
|---|---|---|
| `enabled` | boolean (`"frame": true` is shorthand for `{ "enabled": true }`) | `false` |
| `thickness` | px, or per side `{ "top", "bottom", "left", "right" }` (0 allowed) | 8 |
| `innerRadius` | px | 18 |
| `outline` | px, line along the inner edge | 1 |

Per-theme defaults:

| Theme | Frame | Thickness | Inner radius | Outline |
|---|---|---|---|---|
| Classic | off | 8 | 18 | 1 |
| Constellation | off | 8 | 22 | 1 |
| Façade | off | 8 | 18 | 1 |
| Modulaire | off | 8 | 18 | 1 |
| Matrix | **on** | 10 | 24 | 0 |

- **Drawing**: one surface on the `bottom` layer (under windows, above the wallpaper), click-through. It fills the screen minus a rounded inner rectangle (even-odd fill), with the bar's opacity.
  - Fill colour: `caseFlat` (Façade), the bar's `caseColor` (Modulaire), otherwise `surface`.
  - Outline colour: `caseEdge` where the theme has one, otherwise `line`.
- **Reservation**: the bar reserves its own side. Each other side with a thickness above 0 gets an invisible `FrameEdge` surface with `exclusiveZone` = its thickness.
- **Bar in a frame**: docked, no islands, no floating, full length. Façade keeps its case gradient on the bar side, and Modulaire keeps its rails on the bar side only.
- **Concentric corners**: set `innerRadius` to about Hyprland's `rounding` + `gaps_out` (e.g. 10 + 8 = 18) so window corners follow the frame.
- **Screen corners**: the theme's `screenCorners` when above 0. Otherwise, with a frame, min(`innerRadius` + thickness, 32).
- **Fullscreen**: the frame and its reservations are removed while a fullscreen window is shown on that screen. A maximised window keeps them.

## Drawers

Panels and hover cards come out of the bar as **merged drawers** (`components/DrawerFrame.qml`):

- **One shape**: the drawer reaches over the bar's inner border (no line at the junction) and has the same fill as its island or bar, opaque so it stays readable. A single border leaves the island's border, follows two concave fillets, then runs around the drawer.
- **Fillets**: their radius is the `drawer.fillet` token (Classic 10, Constellation 14, Matrix 12), independent of the control radius. Façade and Modulaire use 0: their cards hang straight.
- **At the end of an island** (screen edge or end of the bar): if the island cannot widen on that side, the drawer aligns with the island's end, without a fillet, and that corner of the island turns square.
- **The island grows**: when the drawer is wider than the island it comes from, the island's background (not its content) widens with an animation to carry the drawer and its fillets, then shrinks back on close.
- **Edges**: the shape is drawn for a bar at the top and rotated for the other edges.
- **Opening**: the drawer deepens out of the bar while its content stays in place and is uncovered as it goes. With reduced motion it appears whole and only fades.

## Animations

Per-theme `motion` tokens, applied by `theme/Motion.qml`:

| Token | Classic | Constellation | Façade | Modulaire | Matrix |
|---|---|---|---|---|---|
| fast / base / slow (ms) | 140 / 200 / 280 | 160 / 230 / 320 | 100 / 150 / 220 | 120 / 180 / 260 | 120 / 160 / 220 |
| Entry easing | `OutCubic` | `OutBack`, overshoot 0.8 | `OutQuad`* | `OutCubic` | `OutQuart` |
| Stagger (ms) | 20 | 30 | 15 | 25 | 0 |

\* `Motion.easing()` only maps `OutBack`, `OutQuart` and `OutQuint`; any other value, Façade's `OutQuad` included, currently plays as `OutCubic`.

- **Exits**: `InCubic`, 0.75 × the duration, no bounce, always from the current value (interruptible). A drawer that grows a zone never overshoots.
- **Fullscreen**: on a screen showing a fullscreen window, every duration is 0.
- **Reduced motion** (`appearance.reducedMotion`, set in Settings › System; by default GNOME's `enable-animations`): durations capped at 90 ms, `OutQuad`, no overshoot and no movement, only fades.
- **Launcher**: scale 0.96 → 1 with a fade. **Settings**: scale 0.98 → 1 with a fade.
- **Dashboards**: modules fade in column by column, delayed by the stagger × their column.

## App icons

Style axis `appIcons` (component `components/AppIcon.qml`), overridable in Settings › Appearance (`appearance.appIcons`):

- `native` (Classic, Modulaire): original colours;
- `tinted` (Constellation, Façade): a two-tone version in the accent;
- `mono` (Matrix): a silhouette in the ink colour, using the app's `-symbolic` icon when the icon theme has one.

App icons appear in the tray, the active window widget, the window, workspaces and tray cards, the workspaces module and the clipboard. The launcher keeps the original icons.

- Rendered by a shader (`assets/shaders/appicon.frag`, compiled by `tools/gen-shaders.sh`).
- `appearance.appIconTint` (0.6): strength of the two-tone effect. `appearance.appIconContrast` (0.35): threshold for dimming light areas in mono.
- **Contrast guard** (`appearance.appIconGuard`, on by default): a native or tinted icon whose average colour contrasts less than 1.6:1 with what it sits on gets its lightness inverted, hue kept.
- Badges drawn inside an icon (such as Discord's red dot) are recoloured too: the shader cannot tell them apart from a red icon.
