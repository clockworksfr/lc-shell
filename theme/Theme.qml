pragma Singleton

import QtQuick
import Quickshell

// Neutral design tokens. Components read only from here, never hardcode
// colors or sizes, so an art direction can later replace this file
// (or swap token sets) without touching the modules.
Singleton {
    readonly property QtObject color: QtObject {
        readonly property color bg: "#1c1c1c"
        readonly property color surface: "#2a2a2a"
        readonly property color fg: "#e6e6e6"
        readonly property color fgMuted: "#8c8c8c"
        readonly property color accent: "#d0d0d0"
        readonly property color urgent: "#e06c5a"
    }

    readonly property QtObject space: QtObject {
        readonly property int xs: 4
        readonly property int s: 8
        readonly property int m: 12
        readonly property int l: 16
        readonly property int xl: 24
    }

    readonly property QtObject radius: QtObject {
        readonly property int none: 0
        readonly property int s: 4
        readonly property int m: 8
        readonly property int full: 999
    }

    readonly property QtObject font: QtObject {
        readonly property string family: "sans-serif"
        readonly property string mono: "monospace"
        readonly property int sizeS: 11
        readonly property int sizeM: 13
        readonly property int sizeL: 16
    }

    readonly property QtObject bar: QtObject {
        readonly property int height: 32
    }
}
