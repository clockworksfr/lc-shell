pragma Singleton

import QtQuick
import Quickshell

// Tile types usable in dashboard pages ("type" of a cell).
Singleton {
    readonly property var tiles: ({
            clock: "Clock.qml",
            media: "Media.qml",
            system: "System.qml",
            window: "Window.qml",
            workspaces: "Workspaces.qml"
        })

    // Tiles drawn without a card frame.
    readonly property var frameless: ["window"]

    function url(type: string): url {
        return Qt.resolvedUrl(tiles[type] ?? "Unknown.qml");
    }
}
