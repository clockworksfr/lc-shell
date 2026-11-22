pragma Singleton

import QtQuick
import Quickshell

// Constellation (replaces Ligne): floating glass islands, space mood,
// stars, comet progress, orbits. Concept inspired by Nebula
// (github.com/LilaccFlowerr/Nebula, AGPL-3.0; no code taken).
// docs/themes.md, section 2. Night = dark variant, dawn = light.
Singleton {
    readonly property var definition: ({
            id: "constellation",
            name: "Constellation",
            palettes: {
                dark: {
                    bg: "#0B0E1A",
                    surface: "#141A2B",
                    surface2: "#1C2338",
                    surface3: "#262E47",
                    ink: "#E6E9F5",
                    soft: "#9AA3BF",
                    line: "#2A3350",
                    accent: "#9FB8FF",
                    accent2: "#F2A7D8",
                    onAccent: "#0E1430",
                    urgent: "#FF7A8A",
                    warn: "#FFD27A",
                    ok: "#7EE0B5",
                    glass: "#14FFFFFF",
                    star: "#B0FFFFFF"
                },
                light: {
                    bg: "#EEF0F8",
                    surface: "#FFFFFF",
                    surface2: "#F3F4FB",
                    surface3: "#E4E7F4",
                    ink: "#171B2E",
                    soft: "#5A6180",
                    line: "#D8DCEC",
                    accent: "#4255C8",
                    accent2: "#C2408F",
                    onAccent: "#FFFFFF",
                    urgent: "#C93A4E",
                    warn: "#956400",
                    ok: "#23805B",
                    glass: "#99FFFFFF",
                    star: "#8A3A4680"
                }
            },
            font: {
                family: "Outfit",
                mono: "Geist Mono",
                display: "Outfit",
                heroScale: 1.04,
                displayWeight: 300,
                sizeS: 12,
                sizeM: 14,
                sizeL: 17,
                sizeXL: 28
            },
            space: {
                xs: 6,
                s: 10,
                m: 14,
                l: 20,
                xl: 28,
                xxl: 36
            },
            radius: {
                control: 16,
                tile: 22,
                panel: 24,
                card: 24
            },
            border: {
                width: 1
            },
            motion: {
                fast: 160,
                base: 230,
                slow: 320,
                duration: 230,
                easing: "OutBack",
                overshoot: 0.8,
                stagger: 30
            },
            drawer: {
                fillet: 14
            },
            bar: {
                height: 44,
                verticalWidth: 52,
                style: "islands",
                floating: true,
                margin: 10,
                radius: 22,
                opacity: 0.86,
                border: 1,
                padding: 16,
                spacing: 14,
                screenCorners: 18,
                frame: {
                    enabled: false,
                    thickness: 8,
                    innerRadius: 22,
                    outline: 1
                }
            },
            style: {
                workspaces: "stars",
                appIcons: "tinted",
                // Top highlight on islands and panels (theme `glass` color).
                glass: true
            }
        })
}
