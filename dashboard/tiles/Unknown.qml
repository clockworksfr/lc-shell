import QtQuick
import Quickshell
import qs.components
import qs.theme

// Placeholder for a tile type that isn't in the registry.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    property string type
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    ThemedText {
        anchors.centerIn: parent
        text: `?${root.type}`
        color: root.theme.color.urgent
    }
}
