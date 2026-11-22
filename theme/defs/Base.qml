pragma Singleton

import QtQuick
import Quickshell

// Tokens every theme starts from. A theme definition only lists what it
// changes; Themes.resolve() deep-merges it over this.
//
// Shape of a resolved theme (what components read):
//   color   bg, surface, surfaceAlt, fg, fgMuted, line, accent, onAccent, urgent
//   font    family, mono, display, sizeS/M/L/XL
//   space   xs, s, m, l, xl
//   radius  none, s, m, l, full
//   border  width
//   hit     minimum size of a touch/click target (bigger on touch screens)
//   bar     default bar look, overridable per screen in shell.json
//   style   component variants ("axes"); components never test theme ids
Singleton {
    readonly property var definition: ({
            palettes: {
                dark: {
                    bg: "#1c1c1c",
                    surface: "#2a2a2a",
                    surfaceAlt: "#333333",
                    fg: "#e6e6e6",
                    fgMuted: "#8c8c8c",
                    line: "#3a3a3a",
                    accent: "#d0d0d0",
                    onAccent: "#1c1c1c",
                    urgent: "#e06c5a"
                },
                light: {
                    bg: "#f2f2f2",
                    surface: "#ffffff",
                    surfaceAlt: "#e8e8e8",
                    fg: "#1c1c1c",
                    fgMuted: "#707070",
                    line: "#d6d6d6",
                    accent: "#303030",
                    onAccent: "#ffffff",
                    urgent: "#c0392b"
                }
            },
            font: {
                family: "sans-serif",
                mono: "monospace",
                display: "sans-serif",
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
                xl: 24
            },
            radius: {
                none: 0,
                s: 4,
                m: 8,
                l: 12,
                full: 999
            },
            border: {
                width: 0
            },
            hit: {
                pointer: 24,
                touch: 48
            },
            bar: {
                height: 32,
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
                screenCorners: 0
            },
            style: {
                // Text case of small labels: "none" | "upper"
                labelCase: "none",
                // Workspaces indicator: "labels" | "dots"
                workspaces: "labels"
            }
        })
}
