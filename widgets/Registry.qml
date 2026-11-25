pragma Singleton

import QtQuick
import Quickshell

// Maps the widget names used in a bar's zones (settings.json, `bar.left` /
// `center` / `right`) to their implementation. An entry is either a name
// ("clock") or an object with a "type" and widget-specific options
// ({ "type": "clock", "format": "HH:mm" }).
Singleton {
    readonly property var widgets: ({
            battery: "Battery.qml",
            bluetooth: "Bluetooth.qml",
            clock: "Clock.qml",
            dynamicIsland: "DynamicIsland.qml",
            lights: "Lights.qml",
            media: "Media.qml",
            modes: "Modes.qml",
            network: "Network.qml",
            quickSettings: "QuickSettings.qml",
            notifications: "Notifications.qml",
            system: "System.qml",
            tray: "Tray.qml",
            window: "Window.qml",
            volume: "Volume.qml",
            weather: "Weather.qml",
            wifi: "Wifi.qml",
            workspaces: "Workspaces.qml"
        })

    function typeOf(entry: var): string {
        return typeof entry === "string" ? entry : (entry?.type ?? "");
    }

    function optionsOf(entry: var): var {
        return typeof entry === "string" ? {} : (entry ?? {});
    }

    function url(type: string): url {
        return Qt.resolvedUrl(widgets[type] ?? "Unknown.qml");
    }
}
