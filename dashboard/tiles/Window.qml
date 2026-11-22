import QtQuick
import Quickshell
import qs.components
import qs.theme
import qs.i18n

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
        text: I18n.tr("tile.window")
        color: root.theme.color.fgMuted
    }
}
