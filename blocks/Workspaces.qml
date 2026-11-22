import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.theme

// Workspaces of the screen the block is on (special workspaces excluded).
// Click to focus. Look follows theme.style.workspaces: "labels" | "dots".
Row {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property ShellScreen screen
    property var options: ({})

    readonly property var workspaces: Hyprland.workspaces.values
        .filter(ws => ws.id > 0 && ws.monitor?.name === root.screen?.name)
        .sort((a, b) => a.id - b.id)

    readonly property bool dots: theme.style.workspaces === "dots"

    spacing: dots ? root.theme.space.s : root.theme.space.xs

    Repeater {
        model: root.workspaces

        Rectangle {
            required property HyprlandWorkspace modelData

            readonly property color dotColor: modelData.urgent ? root.theme.color.urgent
                : modelData.active ? root.theme.color.accent
                : root.theme.color.fgMuted

            implicitWidth: root.dots ? (modelData.active ? 20 : 8) : Math.max(root.theme.bar.height - root.theme.space.s, label.implicitWidth + root.theme.space.s * 2)
            implicitHeight: root.dots ? 8 : root.theme.bar.height - root.theme.space.s
            anchors.verticalCenter: parent?.verticalCenter
            radius: root.dots ? root.theme.radius.full : root.theme.radius.s
            color: root.dots ? dotColor : modelData.active ? root.theme.color.surface : "transparent"

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 120
                }
            }

            ThemedText {
                id: label
                visible: !root.dots
                anchors.centerIn: parent
                text: parent.modelData.name
                color: parent.modelData.urgent ? root.theme.color.urgent
                     : parent.modelData.active ? root.theme.color.fg
                     : root.theme.color.fgMuted
            }

            MouseArea {
                // Dots are small: keep a comfortable hit area.
                anchors.centerIn: parent
                width: Math.max(parent.width, root.theme.hit)
                height: Math.max(parent.height, root.theme.hit)
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.modelData.id} })`)
            }
        }
    }
}
