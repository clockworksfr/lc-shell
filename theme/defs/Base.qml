pragma Singleton

import QtQuick
import Quickshell

// Tokens every theme starts from. A theme definition only lists what it
// changes; Themes.resolve() deep-merges it over this. Role names follow
// docs/themes.md.
//
// Shape of a resolved theme (what components read):
//   color   bg, surface, surface2, surface3, ink, soft, line,
//           accent, onAccent, urgent, warn, ok
//   font    family, mono, display, sizeS/M/L/XL
//   space   xs, s, m, l, xl, xxl
//   radius  none, control, tile, panel, card, full
//   border  width
//   motion  duration (ms)
//   hit     minimum size of a click/touch target (bigger on touch screens)
//   bar     default bar look, overridable per screen in settings
//   style   component variants ("axes"); components never test theme ids
Singleton {
    readonly property var definition: ({
            palettes: {
                dark: {
                    bg: "#1c1c1c",
                    surface: "#262626",
                    surface2: "#303030",
                    surface3: "#3a3a3a",
                    ink: "#e6e6e6",
                    soft: "#8c8c8c",
                    line: "#3a3a3a",
                    accent: "#d0d0d0",
                    onAccent: "#1c1c1c",
                    urgent: "#e06c5a",
                    warn: "#e0b050",
                    ok: "#8cc87c",
                    // Second accent (gradients, comets); same as accent unless set.
                    accent2: "#d0d0d0",
                    // Glass highlight and decorative stars (themes that use them).
                    glass: "#14ffffff",
                    star: "#80ffffff"
                },
                light: {
                    bg: "#ececec",
                    surface: "#ffffff",
                    surface2: "#f2f2f2",
                    surface3: "#e4e4e4",
                    ink: "#1c1c1c",
                    soft: "#707070",
                    line: "#d6d6d6",
                    accent: "#303030",
                    onAccent: "#ffffff",
                    urgent: "#c0392b",
                    warn: "#9a6a00",
                    ok: "#2e7d3a",
                    accent2: "#303030",
                    glass: "#99ffffff",
                    star: "#60000000"
                }
            },
            font: {
                family: "sans-serif",
                mono: "monospace",
                display: "sans-serif",
                // Weight of big numerals (clocks, gauges).
                displayWeight: 600,
                sizeS: 11,
                sizeM: 13,
                sizeL: 16,
                sizeXL: 24
            },
            space: {
                xs: 4,
                s: 8,
                m: 12,
                l: 16,
                xl: 24,
                xxl: 32
            },
            radius: {
                none: 0,
                control: 6,
                tile: 10,
                panel: 12,
                card: 16,
                full: 999
            },
            border: {
                width: 0
            },
            motion: {
                duration: 180
            },
            hit: {
                pointer: 24,
                touch: 48
            },
            bar: {
                // "top" | "bottom" | "left" | "right"
                position: "top",
                // Thickness of a horizontal bar.
                height: 32,
                // Thickness of a vertical bar.
                verticalWidth: 48,
                // "full": one band · "islands": one background per zone
                style: "full",
                // Detached from the screen edges by `margin`.
                floating: false,
                margin: 0,
                radius: 0,
                // Background opacity (content stays opaque).
                opacity: 1,
                border: 0,
                // Inner padding of the band or of each island.
                padding: 8,
                spacing: 12,
                // Rounded screen corners radius, 0 = none.
                screenCorners: 0,
                // Frame around the screen, the bar being its thick side
                // (docs/themes.md, "Cadre"). `frame: true` in settings is
                // a shorthand for { enabled: true }.
                frame: {
                    enabled: false,
                    // Other sides; a number, or { top, bottom, left, right }.
                    thickness: 8,
                    innerRadius: 18,
                    // Line along the inner edge (px, color `line`).
                    outline: 1
                }
            },
            style: {
                // Text case of small labels: "none" | "upper"
                labelCase: "none",
                // Workspaces indicator: "labels" | "dots" | "stars"
                workspaces: "labels",
                // Glass highlight over the top of islands and panels.
                glass: false
            }
        })
}
