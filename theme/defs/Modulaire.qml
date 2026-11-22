pragma Singleton

import QtQuick
import Quickshell

// Modulaire: Eurorack synth panel (brushed aluminium, screws in the
// corners), orange Nixie numerals with a halo, LEDs, Michroma labels.
// docs/themes.md section 4, tokens from design study 6.
// Fonts bundled: Barlow Condensed, Michroma, Nixie One. Extra colors:
// ghost (unlit), nixie (tube glow), lcd / lcdInk (small LCD), glow.
Singleton {
    readonly property var definition: ({
            id: "modulaire",
            name: "Modulaire",
            palettes: {
                dark: {
                    bg: "#141617",
                    surface: "#2B2C2E",
                    surface2: "#1D1E20",
                    surface3: "#111212",
                    ink: "#E9E7E1",
                    soft: "#A9A69E",
                    line: "#14FFFFFF",
                    ghost: "#1AFF8A2A",
                    accent: "#E8742A",
                    onAccent: "#111212",
                    urgent: "#D2332B",
                    warn: "#E5C230",
                    ok: "#46C46A",
                    accent2: "#5AA0FF",
                    nixie: "#FF8A2A",
                    lcd: "#1A2410",
                    lcdInk: "#C6F37A",
                    lcdAmber: "#2A1606",
                    lcdAmberInk: "#FFB35A",
                    glow: "#EEFF8A2A",
                    glass: "#0DFFFFFF",
                    star: "#00000000"
                },
                light: {
                    bg: "#D6D3CC",
                    surface: "#D3D0C8",
                    surface2: "#BCB8AE",
                    surface3: "#A9A59A",
                    ink: "#18181A",
                    soft: "#4E4C47",
                    line: "#40000000",
                    ghost: "#14C95E1A",
                    accent: "#C95E1A",
                    onAccent: "#FFFFFF",
                    urgent: "#B82A23",
                    warn: "#8A7210",
                    ok: "#2E8F4C",
                    accent2: "#2F6FB5",
                    nixie: "#E8742A",
                    lcd: "#1A2410",
                    lcdInk: "#C6F37A",
                    lcdAmber: "#2A1606",
                    lcdAmberInk: "#FFB35A",
                    glow: "#AAFF8A2A",
                    glass: "#40FFFFFF",
                    star: "#00000000"
                }
            },
            font: {
                family: "Barlow Condensed",
                mono: "Michroma",
                display: "Nixie One",
                // Small LCD windows (clock, system knobs).
                lcd: "Doto LCD",
                lyric: "Doto LCD",
                lyricCaps: true,
                displayWeight: 400,
                heroScale: 1,
                sizeS: 13,
                sizeM: 15,
                sizeL: 18,
                sizeXL: 30
            },
            radius: {
                control: 8,
                tile: 3,
                panel: 3,
                card: 3
            },
            border: {
                width: 1
            },
            drawer: {
                fillet: 4
            },
            motion: {
                fast: 120,
                base: 180,
                slow: 260,
                duration: 180,
                easing: "OutCubic",
                stagger: 25
            },
            bar: {
                height: 56,
                verticalWidth: 64,
                style: "full",
                floating: false,
                margin: 0,
                radius: 0,
                opacity: 1,
                border: 0,
                padding: 14,
                spacing: 8,
                screenCorners: 0
            },
            style: {
                labelCase: "upper",
                statusIcons: true,
                appIcons: "native",
                workspaces: "sequencer",
                glass: false,
                brushed: true,
                screws: true,
                module: "modulaire",
                cover: "screwed",
                ring: "knob",
                display: "lcd"
            }
        })
}
