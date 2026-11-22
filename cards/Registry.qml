pragma Singleton

import QtQuick
import Quickshell

// Hover card of each bar block type (docs/bar-editing.md, "Cartes").
// A card gets `block` (the bar block item) and `screen`.
Singleton {
    readonly property var cards: ({
            battery: "BatteryCard.qml",
            bluetooth: "BluetoothCard.qml",
            clock: "ClockCard.qml",
            dynamicIsland: "DynamicIslandCard.qml",
            media: "MediaCard.qml",
            network: "NetworkCard.qml",
            notifications: "NotificationsCard.qml",
            system: "SystemCard.qml",
            tray: "TrayCard.qml",
            volume: "VolumeCard.qml",
            weather: "WeatherCard.qml",
            window: "WindowCard.qml",
            workspaces: "WorkspacesCard.qml"
        })

    function has(type: string): bool {
        return type in cards;
    }

    function url(type: string): url {
        return cards[type] ? Qt.resolvedUrl(cards[type]) : "";
    }
}
