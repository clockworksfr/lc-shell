pragma Singleton

import QtQuick
import Quickshell

// Matrix: monochrome, dot-matrix numerals, a single red accent
// (Nothing Phone spirit). simon's own DA, docs/themes.md section 5.
// Fonts (Doto, Space Grotesk, Space Mono) are not bundled yet: the
// families fall back to the system defaults.
Singleton {
    readonly property var definition: ({
            id: "matrix",
            name: "Matrix",
            palettes: {
                dark: {
                    bg: "#080808",
                    surface: "#0B0B0B",
                    surface2: "#121212",
                    surface3: "#1A1A1A",
                    ink: "#F2F2F2",
                    soft: "#8C8C8C",
                    line: "#262626",
                    accent: "#D71921",
                    onAccent: "#FFFFFF",
                    urgent: "#E5323A",
                    warn: "#D71921",
                    ok: "#8FCB9F"
                },
                light: {
                    bg: "#E4E4E2",
                    surface: "#F2F2F0",
                    surface2: "#FFFFFF",
                    surface3: "#ECECEA",
                    ink: "#111111",
                    soft: "#7A7A78",
                    line: "#DCDCD9",
                    accent: "#D71921",
                    onAccent: "#FFFFFF",
                    urgent: "#D71921",
                    warn: "#D71921",
                    ok: "#3E7D52"
                }
            },
            font: {
                family: "Space Grotesk",
                mono: "Space Mono",
                display: "Doto"
            },
            radius: {
                control: 999,
                tile: 28,
                panel: 28,
                card: 28
            },
            border: {
                width: 1
            },
            bar: {
                height: 40,
                style: "full",
                floating: false,
                margin: 0,
                radius: 0,
                opacity: 1,
                border: 0,
                screenCorners: 20
            },
            style: {
                labelCase: "upper",
                workspaces: "dots"
            }
        })
}
