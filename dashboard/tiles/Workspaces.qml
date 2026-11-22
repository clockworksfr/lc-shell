import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.theme

// Pages of this screen (its Hyprland workspaces), as large buttons.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    readonly property var workspaces: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor?.name === root.screen?.name).sort((a, b) => a.id - b.id)

    Row {
        anchors.centerIn: parent
        spacing: root.theme.space.s

        Repeater {
            model: root.workspaces

            Rectangle {
                required property HyprlandWorkspace modelData

                width: Math.max(root.theme.hit, 44)
                height: width
                radius: root.theme.radius.control
                color: modelData.active ? root.theme.color.accent : root.theme.color.surface2

                ThemedText {
                    anchors.centerIn: parent
                    text: parent.modelData.name
                    color: parent.modelData.active ? root.theme.color.onAccent : root.theme.color.ink
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.modelData.id} })`)
                }
            }
        }
    }
}
