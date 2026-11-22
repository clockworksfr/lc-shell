pragma Singleton

import QtQuick
import Quickshell

// Matrix: monochrome, dot-matrix numerals, a single red accent
// (Nothing Phone spirit). Palettes from simon's own DA.
// Fonts (Doto, Space Grotesk, Space Mono) arrive with the theme phase;
// until then the families fall back to the system defaults.
Singleton {
    readonly property var definition: ({
            id: "matrix",
            name: "Matrix",
            palettes: {
                dark: {
                    bg: "#0B0B0B",
                    surface: "#121212",
                    surfaceAlt: "#1A1A1A",
                    fg: "#F2F2F2",
                    fgMuted: "#8C8C8C",
                    line: "#262626",
                    accent: "#D71921",
                    onAccent: "#F2F2F2",
                    urgent: "#E5323A"
                },
                light: {
                    bg: "#F2F2F0",
                    surface: "#FFFFFF",
                    surfaceAlt: "#ECECEA",
                    fg: "#111111",
                    fgMuted: "#7A7A78",
                    line: "#DCDCD9",
                    accent: "#D71921",
                    onAccent: "#FFFFFF",
                    urgent: "#D71921"
                }
            },
            font: {
                family: "Space Grotesk",
                mono: "Space Mono",
                display: "Doto"
            },
            radius: {
                s: 999,
                m: 12,
                l: 16
            },
            border: {
                width: 1
            },
            bar: {
                height: 34,
                style: "full",
                floating: false,
                margin: 0,
                radius: 0,
                opacity: 1,
                border: 1
            },
            style: {
                labelCase: "upper",
                workspaces: "dots"
            }
        })
}
