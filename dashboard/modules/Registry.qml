pragma Singleton

import QtQuick
import Quickshell

// Module types usable in dashboard pages ("type" of a cell).
Singleton {
    readonly property var modules: ({
            clock: "Clock.qml",
            hue: "Hue.qml",
            lyrics: "Lyrics.qml",
            media: "Media.qml",
            showcase: "ShowcaseButton.qml",
            system: "System.qml",
            themeSwitch: "ThemeSwitch.qml",
            toggles: "Toggles.qml",
            vu: "Vu.qml",
            weather: "Weather.qml",
            window: "Window.qml",
            workspaces: "Workspaces.qml"
        })

    // Modules drawn without a card frame.
    readonly property var frameless: ["window"]

    function url(type: string): url {
        return Qt.resolvedUrl(modules[type] ?? "Unknown.qml");
    }
}
