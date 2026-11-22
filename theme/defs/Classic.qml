pragma Singleton

import QtQuick
import Quickshell

// Classique moderne: the default theme.
// PROVISIONAL values until the design spec is in (docs/architecture.md).
Singleton {
    readonly property var definition: ({
            id: "classic",
            name: "Classique",
            palettes: {
                dark: {
                    bg: "#15161a",
                    surface: "#1f2026",
                    surfaceAlt: "#2a2b32",
                    fg: "#e8e8ec",
                    fgMuted: "#8d8f99",
                    line: "#30313a",
                    accent: "#8ab4f8",
                    onAccent: "#0e1116",
                    urgent: "#f2766b"
                },
                light: {
                    bg: "#f4f4f6",
                    surface: "#ffffff",
                    surfaceAlt: "#ebebef",
                    fg: "#1b1c21",
                    fgMuted: "#6b6d78",
                    line: "#dcdce2",
                    accent: "#3b6fd8",
                    onAccent: "#ffffff",
                    urgent: "#d0463b"
                }
            },
            bar: {
                height: 36,
                style: "islands",
                floating: true,
                margin: 8,
                radius: 12,
                opacity: 0.92,
                padding: 12
            }
        })
}
