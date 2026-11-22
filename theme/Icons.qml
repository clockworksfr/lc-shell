pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Icon names -> characters of the bundled icon fonts (assets/fonts/symbols,
// built by tools/gen-icons.py from Material Symbols Rounded, Apache 2.0).
Singleton {
    id: root

    property var codepoints: ({})

    function glyph(name: string): string {
        const hex = codepoints[name];
        return hex ? String.fromCodePoint(parseInt(hex, 16)) : "";
    }

    FileView {
        path: Quickshell.shellDir + "/assets/fonts/symbols/icons.json"
        onLoaded: root.codepoints = JSON.parse(text())
    }
}
