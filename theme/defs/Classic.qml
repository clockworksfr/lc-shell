pragma Singleton

import QtQuick
import Quickshell

// Classique moderne: the default theme (docs/themes.md, section 1).
// Not yet implemented from the spec: shadows, icon font, dynamic center
// island, component variants beyond tokens.
Singleton {
    readonly property var definition: ({
            id: "classic",
            name: "Classique",
            palettes: {
                dark: {
                    bg: "#0F1114",
                    surface: "#171A1E",
                    surface2: "#20242A",
                    surface3: "#2B3037",
                    ink: "#E9ECEF",
                    soft: "#A1A9B3",
                    line: "#2B3038",
                    accent: "#5FD0A8",
                    onAccent: "#06281D",
                    urgent: "#FF6B5E",
                    warn: "#F2C14E",
                    ok: "#8BD17C",
                    accent2: "#5FD0A8"
                },
                light: {
                    bg: "#E7EAEE",
                    surface: "#FAFBFC",
                    surface2: "#EEF1F4",
                    surface3: "#E1E5EA",
                    ink: "#14171B",
                    soft: "#56606B",
                    line: "#D5DAE1",
                    accent: "#0E7A5C",
                    onAccent: "#FFFFFF",
                    urgent: "#C8372D",
                    warn: "#9A6A00",
                    ok: "#2E7D3A",
                    accent2: "#0E7A5C"
                }
            },
            font: {
                family: "Figtree",
                mono: "JetBrains Mono",
                display: "Figtree",
                displayWeight: 700,
                sizeS: 12,
                sizeM: 14,
                sizeL: 17,
                sizeXL: 28
            },
            radius: {
                control: 10,
                tile: 16,
                panel: 20,
                card: 28
            },
            border: {
                width: 1
            },
            motion: {
                duration: 200
            },
            bar: {
                height: 40,
                verticalWidth: 56,
                style: "islands",
                floating: true,
                margin: 8,
                radius: 14,
                opacity: 0.94,
                border: 1,
                padding: 14,
                spacing: 12,
                screenCorners: 14
            },
            style: {
                workspaces: "dots"
            }
        })
}
