import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.components.dashboard
import qs.theme

// Pages of this screen (its Hyprland workspaces): equal cells filling the
// module (one row in S, a grid in M / L), number and window count.
ModuleBase {
    id: root

    readonly property var workspaces: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor?.name === root.screen?.name).sort((a, b) => a.id - b.id)
    readonly property int count: Math.max(1, workspaces.length)
    // tiny: the active one; narrow: one column; wide / strip: one row;
    // box / tall: 2 or 3 columns.
    readonly property int columns: shape === "narrow" ? 1 : shape === "wide" || shape === "strip" ? count : shape === "tiny" ? 1 : Math.min(count, ratio < 0.8 ? 2 : 3)
    readonly property var activeWs: workspaces.find(w => w.active) ?? workspaces[0] ?? null

    // tiny: the active workspace and "n / total".
    Column {
        visible: root.shape === "tiny"
        anchors.centerIn: parent

        Figure {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.activeWs?.name ?? ""
            pixelSize: root.figure(0.55, 0.5)
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            label: true
            text: `${root.workspaces.indexOf(root.activeWs) + 1} / ${root.workspaces.length}`
            font.pixelSize: root.t4
            color: root.theme.color.soft
        }
    }

    Grid {
        id: grid

        visible: root.shape !== "tiny"
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
                color: modelData.active ? (root.theme.color.signal ?? root.theme.color.accent) : root.theme.color.surface2

                Figure {
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
