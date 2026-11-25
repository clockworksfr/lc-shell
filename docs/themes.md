# Theme specification

Derived from the design study (mockups: “lc-shell renders”, v2). Serves as the reference for phase 2 (implementation in `theme/defs/`). The values are design choices; no code is taken from Caelestia, and the components mentioned are to be recreated.

## Common rules

- **Colour roles**: `bg` (background/desktop), `surface`, `surface2`, `surface3`, `ink`, `soft` (dimmed ink), `line`, `accent`, `onAccent`, `urgent`, `warn`, `ok`, plus roles specific to some themes (`ghost`, `silk`, `vu`…).
- **Layers**: bar and screen corners on `top`. Never `overlay` when the active workspace has a fullscreen window.
- **Densities**: compact 32, normal 40, touch 56 (48 targets). Modules mode: targets ≥ 72.
- **Fonts**: static files only (Qt ignores variable axes); instantiate variable fonts with `fontTools varLib.instancer`.
- **Textures and effects**: disabled during a fullscreen game.

## Bar axes (overridable per screen)

| Axis | Values |
|---|---|
| `layout` | `islands` · `full` · `center` (fixed width, centred) |
| `floating` | 0/1, `margin` 0–24 |
| `radius` | 0–24; attached: only the corners on the windows side |
| `concave` | 0/1, concave corners (attached only) |
| `groups` | `bare` · `caps` (capsules) |
| `opacity` | 0–100 |
| `border` | 0/1/2 px, colour `line` |
| `screenCorners` | 0/12/14/20 |
| `height` | 32/40/44/56 |
| `position` | top/bottom |
| `autoHide` | no/smart |

## 1. Classic (default)

| Role | Dark | Light |
|---|---|---|
| bg | #0F1114 | #E7EAEE |
| surface | #171A1E | #FAFBFC |
| surface2 | #20242A | #EEF1F4 |
| surface3 | #2B3037 | #E1E5EA |
| ink | #E9ECEF | #14171B |
| soft | #A1A9B3 | #56606B |
| line | #2B3038 | #D5DAE1 |
| accent (jade) | #5FD0A8 | #0E7A5C |
| onAccent | #06281D | #FFFFFF |
| urgent | #FF6B5E | #C8372D |
| warn | #F2C14E | #9A6A00 |
| ok | #8BD17C | #2E7D3A |

- **Fonts**: Figtree 400/500/600/700 (OFL, github.com/erikdkennedy/figtree) · JetBrains Mono 400/500/600 (OFL) · Material Symbols Rounded, instances FILL 0 and 1, wght 400, opsz 24 (Apache 2.0).
- **Shapes**: radii island 14, control 10, module 16, panel 20, Xeneon card 28, pill-shaped buttons and sliders. 1 px `line` border on islands and panels, 0 on cards; urgent = 4 px inner edge. Spacing 4/8/12/16/24/32. Shadow 0 4 18 #0000008C (dark) / #1A2A3A2E (light), panels 0 14 40. Animations 160–220 ms OutCubic, no bounce.
- **Bar**: floating islands, margin 8, height 40, radius 14, opacity 94%, border 1, bare groups, screen corners 14.
- **Textures**: none; option: accent derived from the wallpaper.
- **Components**:
  - Workspaces: 8 px dots, active = 27×8 accent pill, occupied = ink at 55%, empty = `line`, urgent = `urgent`.
  - Clock: Figtree SemiBold 15, tabular figures, date in `soft`, centre island.
  - Dynamic centre island, by priority: OSD (1.2 s) > recording > timer > new track (3 s) > time; width animated over 200 ms.
  - Sliders: 44 px pill in panels, 14 px in modules, icon and value inside the track.
  - Progress: rounded 6–8 px bar.
  - Toggles: 112 px two-line modules, active = accent background.
  - Notifications: panel with radius 20, grouped by app.
  - Drawers: slide out of their island.

## 2. Constellation (replaces Ligne, study v4)

Concept inspired by Nebula (github.com/LilaccFlowerr/Nebula, **AGPL-3.0**: concept only, no code taken): floating islands with fixed roles, popups joined to their island by a concave neck, tinted glass without blur, space theme. Differences: fixed palette (no matugen), constellation and stars, comet, orbits, Outfit instead of Inter.

| Role | Night | Dawn |
|---|---|---|
| bg | #0B0E1A | #EEF0F8 |
| surface (86% night, 90% dawn) | #141A2B | #FFFFFF |
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
| glass (top highlight) | #FFFFFF14 | #FFFFFF99 |
| star | #FFFFFFB0 | #3A46808A |

- **Fonts**: Outfit 200/300/400/500/600 (OFL, github.com/Outfitio/Outfit-Fonts) · Geist Mono 400/500 (OFL, github.com/vercel/geist-font) · Material Symbols Rounded FILL 1 wght 400 opsz 24.
- **Shapes**: pill-shaped islands, buttons and sliders; cards 24; modules 22–28; inner controls 16. 1 px border, accent at 16–22%; urgent = 3 px edge + pink glow. 64×12 neck (two concave arcs, r 12). Spacing 6/10/14/20/28. Shadow 0 6 26 #00000080 (night) / #2A3A8A26 (dawn). Motion 200–260 ms OutQuint.
- **Bar**: floating islands, margin 10, height 44, radius 22, opacity 86%, outline 1, bare groups, screen corners 18. Frame (off): thickness 8, inner radius 22, outer corners 30. Vertical: 52 px, time on two lines in Outfit 300.
- **Textures**: glass = surface at 86% + 8% white highlight over the top 58%, no blur; star field in a Canvas painted once (140 and 97 px grids), optional, never redrawn during a game; glows (≤ 16 px) limited to the active star, the comet and the cover art.
- **Components**: workspaces = constellation (empty: 1.5 px circle; occupied: dot; active: 4-pointed accent star with glow; urgent: ringed pink dot; glowing gradient thread); clock in Outfit 300 (200 when large); progress = comet (2 px stroke, accent2 → accent trail, 10 px head); gradient pill sliders; primary button with a 135° gradient; monitoring as orbits (planet at value × 360°); cards and drawers joined by a neck.
- **Xeneon**: media (round cover with glow, lyrics, comet, 110–130 px buttons), CPU/GPU/RAM orbits, Outfit 200 clock + weather + agenda, do-not-disturb / microphone / replay / timer modules, urgent card with a pink edge.

## 3. Façade (hi-fi amplifier, VFD display)

| Role | Dark (VFD) | Light (aluminium + LCD) |
|---|---|---|
| bg | #0D1112 | #C9CCC6 |
| surface (faceplate) | #1B1E20 | #D7D8D5 |
| surface2 (glass/LCD) | #030505 | #B6BEA1 |
| surface3 (modules, keys) | #2B2F31 | #D4D5D2 |
| ink | #6EF3D6 (phosphor) | #1D2618 (segments) |
| soft | #6EF3D66B | #1D261873 |
| ghost (unlit segments) | #6EF3D616 | #1D261814 |
| silk (silkscreen) | #C9CCC4 | #1E2022 |
| line | #000000 | #8F9295 |
| accent | #6EF3D6 | #1E8C7B |
| urgent (amber) | #FFB547 | #A85A00 |
| critical | #FF4A3D | #C8392C |
| vu (dial) | #F1DFAE | #F1DFAE |

- **Fonts**: DSEG7 Classic Bold/Regular, DSEG14 Classic Bold (OFL, github.com/keshikan/DSEG) · static Doto wght 900 ROND 0 (OFL, github.com/oliverlalan/Doto), falling back to DotGothic16 · IBM Plex Sans Condensed 500/600/700.
- **Shapes**: radii display 4, module 6, key 8; bar 0 at the top, 6 at the bottom. Border 2 px #000 (dark) / 1 px #8F9295 (light); 1 px top bevel, white at 12–30%. Spacing 8/14/24; Ø 10 screws 18 px from the corners; Xeneon keys 140×120.
- **Bar**: centred, fixed width 2560, attached, height 44, bottom radius 6, opaque, border 2, capsule groups, square corners.
- **Textures**: dark = VFD mesh as a static ShaderEffect (1 px line every 3 px, white at 2–3%), 8% ghost segments (“88:88” under the value), glow = text doubled at 50% + 0.35 em shadow. Light = brushed aluminium (1 px streaks at 3%), no glow.
- **Components**:
  - Workspaces: 7-segment; active lit with glow, occupied 42%, empty ghost, urgent amber.
  - Lit/ghost indicator lights: BT, VPN, REC, MSG, NET, GAME.
  - Clock: DSEG7.
  - Sliders: fader (56×30 knob, 4 px rail) or 24-cell bar graph.
  - Progress: 8/6 dashes.
  - Damped-needle VU meter (SmoothedAnimation 0.25 s) + spectrum in columns of dots.
  - Buttons: rectangular keys with LEDs.
  - Notifications: scrolling in the display + list in Plex Condensed.

## 4. Modulaire (Eurorack synth)

| Role | Dark (black anodised) | Light (aluminium) |
|---|---|---|
| bg | #141617 | #D6D3CC |
| surface → surface2 (panel gradient) | #2B2C2E → #1D1E20 | #D3D0C8 → #BCB8AE |
| case (case, rails) | #111212 | #191A1A |
| ink (silkscreen) | #E9E7E1 | #18181A |
| line | #FFFFFF14 | #00000040 |

Shared: LCD #1A2410 on #C6F37A, Nixie #FF8A2A, audio (accent) #E8742A, system #E5C230, alert #D2332B, green LED #46C46A, network #5AA0FF (dark) / #2F6FB5 (light).

- **Fonts**: Michroma, Barlow Condensed 500/600/700, Nixie One, static Doto (LCD). OFL.
- **Shapes**: radii module 3, button 8, CRT 18; round knobs and jacks. 1 px inner border; 6 px (1U) and 26 px (3U) rails drilled every 20 px. 1 HP = 20 px, 8 px between modules; 180×120 transport buttons.
- **Bar**: centred 2800 px 1U rail, attached, height 56, radius 0, opaque, no border, groups = modules, square corners.
- **Textures**: brushed aluminium (vertical 1 px streaks at 2–3% + 10% central highlight), corner screws, Nixie glow (three orange shadows), LEDs with a 0.6 em glow, cables as Shape/PathCubic 11 px (16 px outline). LEDs at 4 Hz, 1 Hz during a game.
- **Components**: workspaces as a 9-step sequencer; Nixie clock; fader + rotary knob (vertical drag), flat sliders on a laptop; LED ladders (green, yellow ≥ 70%, red ≥ 85%); OSD as an LED ring + “VOL 64” LCD; audio patching: Ø 46 jacks (96 hit area), one cable = one PipeWire link.

## 5. Matrix (the author's own design language, Nothing-inspired)

| Role | Dark | Light |
|---|---|---|
| surface | #0B0B0B | #F2F2F0 |
| surfaceDim (background) | #080808 | #E4E4E2 |
| containers 0–4 | #000000 #121212 #1A1A1A #222222 #2C2C2C | #FFFFFF #FAFAF9 #FFFFFF #ECECEA #E3E3E0 |
| ink | #F2F2F2 | #111111 |
| soft | #8C8C8C | #7A7A78 |
| line | #262626 | #DCDCD9 |
| secondary | #A6A6A6 | #5C5C5A |
| red accent (alerts) | #D71921 | #D71921 |
| error | #E5323A | #D71921 |
| success | #8FCB9F | #3E7D52 |

Alert = red with #FFFFFF text.

- **Fonts**: Doto Matrix = static Doto wght 900 ROND 100 (OFL) · Space Grotesk 400/500/600 static (OFL) · Space Mono Regular/Bold (OFL) · Material Symbols Sharp FILL 0 wght 400 opsz 24.
- **Shapes**: pill for all controls; cards radius 28; 1 px `line` outline on controls, cards, notifications; tonal buttons as outline only. 46×104 pill slider (radius 23), 40 pill toggle (radius 20), 6 px dots, modules 16 apart.
- **Bar**: full, attached, height 40, opaque (`surface`), bare groups, no border, screen corners 20. Workspaces on the left, clock in the centre, status on the right.
- **Textures**: dot grid (pitch 16, radius 1.1, ink at 16% in light / 13% in dark, on `surfaceDim`), painted once; glow on the active LED in dark mode only (blur 0.8, max 6).
- **Components**:
  - Space Mono uppercase labels; figures in Doto Matrix; dotted progress.
  - Dashboard of modules: clock, week, weather in dot glyphs, dot rings, media with a disc and dotted progress, pill sliders and toggles that invert.
  - Dot-ring visualiser; idle animation in dots; dot-grid background.
  - States: label at 80% in `soft` above the value, value in red on alert; 0.68/0.8 scale below 900 px of height.
  - Workspaces: 6×6 LEDs (`line` when empty, ink when occupied), active = 14×6 bar, 8 px before a Space Mono number.
  - Notifications: mono header with an 8 px red dot, short title in Doto (22), actions = ink pill + outline pill, 3 px light strip at 40% width, red if critical.
  - To recreate in lc-shell: dot arc, dot equaliser, dot icons, dot grid, Matrix stat.

## Frame and bar position (study v3)

### Axes (Classic defaults)

| Axis | Values | Default |
|---|---|---|
| `bar.position` | `top` · `bottom` · `left` · `right` | `top` |
| `bar.frame.enabled` | boolean | `false` |
| `bar.frame.thickness` | 4–16, overridable per side (`top`/`bottom`/`left`/`right`, 0 allowed) | 8 |
| `bar.frame.innerRadius` | 4–32 | 18 |
| `bar.frame.opacity` | 0–100 (always the bar's) | 100 |
| `bar.frame.outline` | 0/1/2 px, colour `line` | 1 |
| `bar.frame.color` | role | `surface` |
| `bar.verticalWidth` | 48 compact · 56 normal · 72 touch | 56 |
| `screenCorners` | `auto` with the frame = min(innerRadius + thickness, 32) | — |

### Per-theme defaults

| Theme | Frame | Thickness | Inner radius | Opacity | Outline | Outer corners | Vertical width |
|---|---|---|---|---|---|---|---|
| Classic | no | 8 | 18 | 100 | 1 | 26 | 56 |
| Constellation | no | 8 | 22 | 86 | 1 | 30 | 52 |
| Façade | no | 12 | 6 | 100 | 2 | 18 | 64 |
| Modulaire | no | 14 | 4 | 100 | 0 | 18 | 72 |
| Matrix | **yes** | 10 | 24 | 100 | 0 | 32 | 56 |

Default position `top` everywhere.

### Layer-shell geometry

- **Without frame**: one bar surface anchored to its edge and to the two neighbouring edges; `exclusiveZone` = margin + thickness (Classic floating islands: 8 + 40 = 48 horizontally, 8 + 56 = 64 vertically); Hyprland adds `gaps_out`.
- **With frame**:
  - Reservation: four invisible surfaces without input, one per edge (anchored to that edge and its neighbours), `exclusiveZone` = thickness of that side; the bar side reserves the bar's thickness.
  - Drawing: one fullscreen surface on the `top` layer, `exclusionMode: Ignore`, even-odd ring = outer rectangle (outer-corner radius) minus inner rectangle (`innerRadius`). Input mask = bar side + open drawers.
  - `innerRadius` ≈ Hyprland `rounding` + `gaps_out` (10 + 8 = 18) for concentric corners.
  - In frame mode: islands, floating and auto-hide are ignored, margin 0; bare or capsule groups depending on the theme.
- **Merged drawer** (coordinates: u along the edge, v inwards; v0 = thickness of the side, p = position, L = length, d = depth, rf = rd = max(8, innerRadius)): start at (p − rf, v0 − 2); concave arc rf to (p, v0 + rf); line to (p, v0 + d − rd); convex arc to (p + rd, v0 + d); line to (p + L − rd, v0 + d); convex arc to (p + L, v0 + d − rd); line to (p + L, v0 + rf); concave arc to (p + L + rf, v0); close inside the frame. Screen: top (u, v), bottom (u, H − v), left (v, u), right (W − v, u); bottom and left: arc direction reversed. Opening: d from 0 to its value in 200 ms OutCubic, fixed fillets, content fades in from 60%. Rendering: even-odd `Shape` or SDF in a `ShaderEffect`.
- **Fullscreen** (window in mode 2 on the active workspace): thicknesses animated to 0 over 180 ms, reservations at 0, empty mask, drawers closed; never `overlay`. A maximised window (mode 1) keeps the frame.
- **Xeneon in modules mode**: no frame by default; with a frame, the modules become the thick sides (window area = the hole). While a game runs on the main monitor, the Xeneon keeps its frame and receives OSD and urgent items.

### Vertical bar (top to bottom)

1. Launcher (square button as wide as the bar).
2. Active app icon, then stacked workspaces (scroll wheel beyond 10). Classic: 8 px dots, active = upright 8 × 27 pill.
3. Spacer.
4. Clock on two lines (HH / MM, tabular figures), optional date (0.7 em).
5. Spacer.
6. Media: 32 px cover with a progress ring; the title moves into the drawer.
7. Status: icon + 2–3 character value below (0.7 em).
8. Tray as a column: 20 px icons, 5 visible then “⋯”.
9. Notifications, then session.

Never rotated text; no window title. Body text ≈ 0.27 × width. Vertical islands: three islands as wide as the bar, 8 px from the edge (top: launcher and workspaces; middle: clock; bottom: media, status, tray, notifications).

### Popups by edge

| Edge | Anchor | Direction | Alignment |
|---|---|---|---|
| Top | bottom of the bar | downwards | centred on the trigger, kept 8 px from the edges |
| Bottom | top of the bar | upwards | same |
| Left | right edge of the bar | rightwards | vertically centred |
| Right | left edge of the bar | leftwards | same |

- Without frame: 8 px gap, radius 20, shadow, 12 px slide + 180 ms fade. With frame: merged drawer.
- Settings, media and calendar come out on the bar side. Notifications on the right (on the left if the bar is on the right). Session on the right, in the middle. Launcher: centred (without frame), on the side opposite the bar (with frame).
- 5K ultrawide (5120×2160) with the bar on the left: 64 px out of 5120 (1.25%) vs 48 out of 2160 (2.2%); the left edge is far from the line of sight: toasts, OSD and launcher stay in the centre.

## Drawers (panels and hover cards)

- A panel or a card comes out of the bar as a **merged drawer**: it covers the bar's inner border (no line at the junction), has the same fill as the island or bar (opaque to stay readable), and a single border that starts from the island's, follows two concave fillets, then runs around the drawer.
- Fillet radius: `drawer.fillet` token (Classic 10, Constellation 14, Matrix 12), independent of the control radius.
- **At the end of an island** (screen or bar edge): if the island cannot widen on that side, the drawer aligns with the end of the island, without a fillet, and that corner of the island becomes square.
- **The island grows**: when the drawer is wider than the island it comes from, the island's background (not its content) widens, with an animation, to carry the drawer and its fillets, then returns to its size on close.

## Animations

Per-theme `motion` tokens, applied by the `Motion` singleton:

| Token | Classic | Constellation | Matrix |
|---|---|---|---|
| fast / base / slow | 140 / 200 / 280 ms | 160 / 230 / 320 ms | 120 / 160 / 220 ms |
| Enter | `OutCubic` | `OutBack`, overshoot 0.8 | `OutQuart` |
| Stagger between rows | 20 ms | 30 ms | 0 |

- **Exit**: `InCubic`, duration × 0.75, no bounce, always from the current value (interruptible).
- **Fullscreen game**: on the affected screen, all durations are 0.
- **Reduced motion** (`appearance.reducedMotion`, defaults to GNOME's `enable-animations` value): fades of at most 90 ms, no movement.
- Drawers: content appears from 40% of the opening and fades out first on close. Launcher: scale 0.96 → 1. Settings: scale 0.98 → 1, and page changes fade with an 8 px rise. OSD: from its edge. Notifications: slide in from their side, the stack closes up. Dashboard: modules fade in, column by column.

## App icons

`appIcons` style axis (`AppIcon` component), overridable in Settings › Appearance (`appearance.appIcons`):

- `native` (Classic): original colours;
- `tinted` (Constellation): desaturated and tinted with the accent;
- `mono` (Matrix): monochrome, in the ink colour.

Applied to the tray, the active window widget and the cards (window, workspaces, tray). The launcher keeps the original icons.

- Rendered by a shader (`assets/shaders/appicon.frag`, compiled by `tools/gen-shaders.sh`).
- `appearance.appIconTint` (0.6): strength of the two-tone effect; `appearance.appIconContrast` (0.35): threshold for dimming light areas in mono.
- **Contrast guard** (`appearance.appIconGuard`, enabled): an original or tinted icon whose average colour has a contrast below 1.6:1 against the bar gets its lightness inverted, hue kept.
- Badges drawn inside an icon (Discord's red dot) follow the recolouring: a shader cannot tell them apart from a red icon.

## Façade and Modulaire implementation (design 6)

- Definitions in `theme/defs/Facade.qml` and `theme/defs/Modulaire.qml`, tokens from study 6 (light and dark palettes, fonts, radii, `drawer.fillet` 6 and 4, `motion`, `appIcons`).
- Bundled fonts (OFL): IBM Plex Sans Condensed, IBM Plex Mono, DSEG7 Classic (Façade); Barlow Condensed, Michroma, Nixie One (Modulaire).
- Extra colours: `ghost` (unlit segments), `glow` (glow of the large figures), `silk` (silkscreen, Façade), `nixie`, `lcd`, `lcdInk` (Modulaire).
- `font.heroScale`: width correction for the large figures (Façade 0.74, Matrix 0.8, Constellation 1.04).
- `HeroText` (large-figures component): unlit segments behind the value if `style.ghostDigits` (Façade, “88:88”), glow if `color.glow` is not transparent (Façade and Modulaire, Matrix in dark mode); a single `MultiEffect` per figure.
- Not rendered yet: segment-style workspaces (Façade) or sequencer-style workspaces (Modulaire), which fall back to labels; brushed aluminium and screws for Modulaire; Façade scan lines.
