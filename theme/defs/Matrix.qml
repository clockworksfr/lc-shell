pragma Singleton

import QtQuick
import Quickshell

// Matrix: monochrome, dot-matrix numerals, a single red accent
// (Nothing Phone spirit). simon's own DA, docs/themes.md section 5.
// Fonts bundled: Space Grotesk, Space Mono, Doto Matrix (static Doto,
// wght 900, ROND 100, made with tools/instance-font.py).
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
                    // Ink is the accent; red is kept for alerts (spec).
                    accent: "#F2F2F2",
                    onAccent: "#0B0B0B",
                    urgent: "#E5323A",
                    warn: "#A6A6A6",
                    ok: "#8FCB9F",
                    accent2: "#8C8C8C",
                    // Glow of dot-matrix figures (dark only).
                    glow: "#B3F2F2F2",
                    // Red touches beyond alerts (design: today, active
                    // workspace, play, progress head, slider handle).
                    signal: "#E5323A"
                },
                light: {
                    bg: "#E4E4E2",
                    surface: "#F2F2F0",
                    surface2: "#FFFFFF",
                    surface3: "#ECECEA",
                    ink: "#111111",
                    soft: "#7A7A78",
                    line: "#DCDCD9",
                    accent: "#111111",
                    onAccent: "#F2F2F0",
                    urgent: "#D71921",
                    warn: "#5C5C5A",
                    ok: "#3E7D52",
                    accent2: "#7A7A78",
                    signal: "#D71921"
                }
            },
            font: {
                family: "Space Grotesk",
                mono: "Space Mono",
                display: "Doto Matrix",
                // Lyrics and the playing track, in dots.
                lyric: "Doto Matrix",
                heroScale: 0.8,
                displayWeight: 400
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
            motion: {
                fast: 120,
                base: 160,
                slow: 220,
                duration: 160,
                easing: "OutQuart",
                stagger: 0
            },
            drawer: {
                fillet: 12
            },
            bar: {
                height: 40,
                verticalWidth: 56,
                style: "full",
                floating: false,
                margin: 0,
                radius: 0,
                opacity: 1,
                border: 0,
                // Micro-label stacks are narrow: generous room between them.
                spacing: 22,
                screenCorners: 32,
                frame: {
                    enabled: true,
                    thickness: 10,
                    innerRadius: 24,
                    outline: 0
                }
            },
            style: {
                labelCase: "upper",
                // Matrix statuses are text (label over value), no icons.
                statusIcons: false,
                appIcons: "mono",
                workspaces: "dots",
                module: "matrix",
                cover: "disc",
                ring: "dots",
                // The bar's clock: the time alone, in the display font
                // (Doto, ~2/3 of the bar), as in the mockup.
                barClock: "display",
                // Statuses as micro labels over their value ("VOL / 64").
                statusStack: true
            }
        })
}
