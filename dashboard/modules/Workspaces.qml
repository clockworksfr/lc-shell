import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.theme

// Pages of this screen (its Hyprland workspaces): equal cells filling the
// module (one row in S, a grid in M / L), number and window count.
ModuleBase {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor?.name === root.screen?.name).sort((a, b) => a.id - b.id)
    readonly property int count: Math.max(1, workspaces.length)
    readonly property int columns: tier === "S" || rows < 2 ? count : Math.ceil(count / (tier === "L" ? 2 : 2))

    Grid {
        id: grid

        anchors.fill: parent
        columns: root.columns
        spacing: root.gap / 1.5

        Repeater {
            model: root.workspaces

            Rectangle {
                id: ws

                required property HyprlandWorkspace modelData
                readonly property int windows: Hyprland.toplevels.values.filter(t => t.workspace?.id === modelData.id).length

                width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
                height: (grid.height - grid.spacing * (Math.ceil(root.count / grid.columns) - 1)) / Math.ceil(root.count / grid.columns)
                radius: root.theme.radius.tile
                color: modelData.active ? root.theme.color.accent : root.theme.color.surface2

                HeroText {
                    anchors.centerIn: parent
                    text: ws.modelData.name
                    pixelSize: Math.min(ws.height * 0.5, ws.width * 0.5) * root.hk
                    color: ws.modelData.active ? root.theme.color.onAccent : root.theme.color.ink
                }

                // One dot per window.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: ws.height * 0.1
                    spacing: 4

                    Repeater {
                        model: Math.min(ws.windows, 6)

                        Rectangle {
                            width: Math.max(5, ws.height * 0.05)
                            height: width
                            radius: width / 2
                            color: ws.modelData.active ? root.theme.color.onAccent : root.theme.color.soft
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${ws.modelData.id} })`)
                }
            }
        }
    }
}
