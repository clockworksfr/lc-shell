import QtQuick
import Quickshell
import qs.components
import qs.theme

// Window cell: CellTiler floats windows of this workspace into it.
// Drawn as a faint frame, visible when the cell is empty.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radius.l
        color: "transparent"
        border.width: 1
        border.color: root.theme.color.line
    }

    ThemedText {
        anchors.centerIn: parent
        label: true
        text: "fenêtre"
        color: root.theme.color.fgMuted
    }
}
