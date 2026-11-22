import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.theme

// Workspaces of the screen the block is on (special workspaces excluded).
// Click to focus.
Row {
    id: root

    property ShellScreen screen
    property var options: ({})

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(ws => ws.id > 0 && ws.monitor?.name === root.screen?.name)
        .sort((a, b) => a.id - b.id)

    spacing: Theme.space.xs

    Repeater {
        model: root.workspaces

        Rectangle {
            required property HyprlandWorkspace modelData

            implicitWidth: Math.max(Theme.bar.height - Theme.space.s, label.implicitWidth + Theme.space.s * 2)
            implicitHeight: Theme.bar.height - Theme.space.s
            radius: Theme.radius.s
            color: modelData.active ? Theme.color.surface : "transparent"

            ThemedText {
                id: label
                anchors.centerIn: parent
                text: parent.modelData.name
                color: parent.modelData.urgent ? Theme.color.urgent
                     : parent.modelData.active ? Theme.color.fg
                     : Theme.color.fgMuted
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.modelData.id} })`)
            }
        }
    }
}
