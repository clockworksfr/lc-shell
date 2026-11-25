pragma Singleton

import QtQuick
import Quickshell

// Façade: hi-fi amplifier front, VFD display (cyan phosphor, glowing in
// the dark variant; green LCD in the light one), condensed labels, 2 px
// black bezels. docs/themes.md.
// Fonts bundled: IBM Plex Sans Condensed, IBM Plex Mono, DSEG7 Classic.
// Extra colors: ghost (unlit segments), silk (screen-printed labels),
// glow (phosphor halo).
Singleton {
    readonly property var definition: ({
            id: "facade",
            name: "Façade",
            palettes: {
                dark: {
                    bg: "#0D1112",
                    surface: "#1B1E20",
                    surface2: "#030505",
                    surface3: "#2B2F31",
                    ink: "#6EF3D6",
                    soft: "#996EF3D6",
                    ghost: "#1A6EF3D6",
                    silk: "#C9CCC4",
                    line: "#000000",
                    accent: "#6EF3D6",
                    onAccent: "#030505",
                    urgent: "#FF4A3D",
                    warn: "#FFB547",
                    ok: "#6EF3D6",
                    accent2: "#F1DFAE",
                    glow: "#8C6EF3D6",
                    // Display windows (VFD): black glass in the dark, a
                    // grey-green LCD in the light.
                    screen: "#030505",
                    screenEdge: "#000000",
                    glass: "#00000000",
                    star: "#00000000",
                    // Bar case: a dark metal gradient, a
                    // 2 px black edge; the zones' plates; a frame's thin
                    // sides.
                    caseTop: "#2A2D2F",
                    caseMid: "#151718",
                    caseBottom: "#0D0F10",
                    caseEdge: "#000000",
                    caseFlat: "#16181A",
                    plate: "#24282A",
                    // Hover cards: silk text, blocks,
                    // bubbles and tracks.
                    card: "#16181A",
                    cardBlock: "#24282A",
                    cardBubble: "#2E3335",
                    cardInk: "#C9CCC4",
                    cardSoft: "#8E928C"
                },
                light: {
                    bg: "#C9CCC6",
                    surface: "#D7D8D5",
                    surface2: "#B6BEA1",
                    surface3: "#C3C5C0",
                    ink: "#1D2618",
                    soft: "#A61D2618",
                    ghost: "#141D2618",
                    silk: "#1E2022",
                    line: "#8F9295",
                    // The light VFD's ink.
                    accent: "#1D2618",
                    onAccent: "#FFFFFF",
                    urgent: "#C8392C",
                    warn: "#A85A00",
                    ok: "#2E7D3A",
                    accent2: "#1E2022",
                    glow: "#00000000",
                    glass: "#00000000",
                    star: "#00000000",
                    screen: "#B6BEA1",
                    screenEdge: "#6F7468",
                    caseTop: "#E2E3E0",
                    caseMid: "#D6D7D4",
                    caseBottom: "#CDCECB",
                    caseEdge: "#8F9295",
                    caseFlat: "#D4D5D2",
                    plate: "#C3C5C1",
                    card: "#D4D5D2",
                    cardBlock: "#C9CAC6",
                    cardBubble: "#BFC1BD",
                    cardInk: "#1E2022",
                    cardSoft: "#4C5052"
                }
            },
            font: {
                family: "IBM Plex Sans Condensed",
                mono: "IBM Plex Mono",
                display: "DSEG7 Classic",
                displayWeight: 700,
                // Slanted segments, like the theme's presentation tab.
                displayItalic: true,
                // Text inside the VFD: 14 segments, upper case (Doto is
                // Matrix's).
                lcd: "DSEG14 Classic",
                lyric: "DSEG14 Classic",
                lyricCaps: true,
                heroScale: 0.74,
                sizeS: 12,
                sizeM: 14,
                sizeL: 17,
                sizeXL: 28
            },
            radius: {
                control: 8,
                tile: 6,
                panel: 6,
                card: 6
            },
            border: {
                width: 2
            },
            drawer: {
                // Cards hang straight under the bar (no fillets).
                fillet: 0
            },
            motion: {
                fast: 100,
                base: 150,
                slow: 220,
                duration: 150,
                easing: "OutQuad",
                stagger: 15
            },
            bar: {
                // A centered front panel / rail.
                length: 0.66,
                height: 44,
                verticalWidth: 64,
                plates: true,
                style: "full",
                floating: false,
                margin: 0,
                radius: 6,
                opacity: 1,
                border: 2,
                padding: 16,
                spacing: 13,
                screenCorners: 0
            },
            style: {
                // The bar's clock in the display font (7 segments / Nixie).
                barClock: "display",
                labelCase: "upper",
                statusIcons: false,
                // Statuses as VFD sigils ("BT 2", "NET ↓1,3M").
                statusSigil: "phosphor",
                appIcons: "tinted",
                workspaces: "segments",
                glass: false,
                ghostDigits: true,
                scanlines: true,
                module: "facade",
                cover: "inset",
                ring: "vu",
                display: "vfd",
                screws: true
            }
        })
}
