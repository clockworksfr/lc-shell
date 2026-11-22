import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.components
import qs.components.dashboard
import qs.theme

// Workspaces of this screen (design study 8, § 6): those Hyprland puts
// on it by its rules, plus any other open there; empty ones stay, dimmed,
// to keep the bearings. Tap: go there. In each theme's language:
//   classic        tiles; the active one filled; a dot per window
//   constellation  connected stars (active ✦ with a halo, busy ✧, empty ·)
//   facade         7-segment figures in display cells (unlit / busy / lit)
//   modulaire      hardware keys with a LED (busy green, active orange)
//   matrix         outlined pills with a LED (active: a glowing bar)
// tiny: the active one alone.
ModuleBase {
    id: root

    readonly property string look: theme.style.module ?? "classic"
    readonly property var monitor: Hyprland.monitorFor(screen)
    property var ruled: []
    readonly property var open: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor?.name === screen?.name)
    // { id, name, ws (HyprlandWorkspace or null) }, by id.
    readonly property var slots: {
        const ids = new Set([...ruled, ...open.map(w => w.id)]);
        return [...ids].sort((a, b) => a - b).map(id => {
            const ws = open.find(w => w.id === id) ?? null;
            return { id: id, name: ws?.name ?? `${id}`, ws: ws };
        });
    }
    readonly property int count: Math.max(1, slots.length)
    readonly property int columns: shape === "narrow" ? 1 : shape === "wide" || shape === "strip" ? count : shape === "tiny" ? 1 : Math.min(count, ratio < 0.8 ? 2 : 3)
    readonly property var activeSlot: slots.find(s => s.ws?.active) ?? slots[0] ?? null

    function windowsOn(id: int): int {
        return Hyprland.toplevels.values.filter(t => t.workspace?.id === id).length;
    }

    // The workspaces Hyprland's rules put on this monitor.
    Process {
        running: !!root.monitor
        command: ["hyprctl", "workspacerules", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const desc = root.monitor?.lastIpcObject?.description ?? "";
                    const name = root.screen?.name ?? "";
                    root.ruled = JSON.parse(text).filter(r => r.monitor === name || (desc && r.monitor === `desc:${desc}`)).map(r => parseInt(r.workspaceString)).filter(n => n > 0);
                } catch (e) {
                    root.ruled = [];
                }
            }
        }
    }

    Grid {
        id: grid

        readonly property int rows: Math.ceil((root.shape === "tiny" ? 1 : root.count) / columns)

        anchors.fill: parent
        columns: root.columns
        spacing: root.gap / 1.5

        Repeater {
            model: root.shape === "tiny" ? (root.activeSlot ? [root.activeSlot] : []) : root.slots

            Item {
                id: cell

                required property var modelData
                required property int index
                readonly property bool active: !!modelData.ws?.active
                readonly property bool urgent: !!modelData.ws?.urgent
                readonly property int windows: root.windowsOn(modelData.id)
                readonly property bool busy: windows > 0
                readonly property real figureSize: Math.min(height * 0.42, width * 0.42) * root.hk

                width: (grid.width - grid.spacing * (grid.columns - 1)) / grid.columns
                height: (grid.height - grid.spacing * (grid.rows - 1)) / grid.rows

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${cell.modelData.id} })`)
                }

                // classic: a tile.
                Rectangle {
                    visible: root.look === "classic"
                    anchors.fill: parent
                    radius: root.theme.radius.tile
                    color: cell.active ? root.theme.color.accent : root.theme.color.surface2
                    opacity: cell.busy || cell.active ? 1 : 0.55
                }

                // facade: a display cell.
                Rectangle {
                    visible: root.look === "facade"
                    anchors.fill: parent
                    radius: 3
                    color: "#030505"
                    border.width: 1
                    border.color: "#000000"
                }

                // modulaire: a hardware key.
                Rectangle {
                    visible: root.look === "modulaire"
                    anchors.fill: parent
                    radius: 4
                    border.width: 1
                    border.color: "#000000"
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: cell.active ? "#E8742A" : "#3A3B3D"
                        }
                        GradientStop {
                            position: 1
                            color: cell.active ? "#B8541A" : "#232426"
                        }
                    }

                    Rectangle {
                        x: 2
                        y: 1
                        width: parent.width - 4
                        height: 1
                        color: "#33FFFFFF"
                    }
                }

                // matrix: an outlined pill.
                Rectangle {
                    visible: root.look === "matrix"
                    anchors.centerIn: parent
                    width: parent.width
                    height: Math.min(parent.height, Math.max(56, parent.width * 0.9))
                    radius: height / 2
                    color: "transparent"
                    border.width: 1
                    border.color: cell.urgent ? "#E5323A" : cell.active ? root.theme.color.ink : root.theme.color.line
                }

                // LED (modulaire, matrix).
                Rectangle {
                    visible: root.look === "modulaire" || root.look === "matrix"
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * (root.look === "matrix" ? 0.24 : 0.14)
                    width: root.look === "matrix" && cell.active ? 22 : root.look === "matrix" ? 8 : 10
                    height: root.look === "matrix" ? 8 : 10
                    radius: height / 2
                    color: root.look === "modulaire"
                        ? (cell.active ? "#FFB070" : cell.busy ? "#46C46A" : "#333333")
                        : (cell.urgent ? "#E5323A" : cell.active ? root.theme.color.ink : cell.busy ? root.theme.color.soft : root.theme.color.line)

                    layer.enabled: (root.look === "modulaire" && (cell.active || cell.busy)) || (root.look === "matrix" && cell.active && Qt.color(root.theme.color.glow ?? "#00000000").a > 0)
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: true
                        shadowEnabled: true
                        shadowColor: root.look === "matrix" ? (root.theme.color.glow ?? "transparent") : cell.active ? "#CCE8742A" : "#CC46C46A"
                        shadowBlur: 0.6
                        blurMax: 10
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                }

                // constellation: a star, connected to the next busy one.
                Text {
                    visible: root.look === "constellation"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -cell.height * 0.1
                    text: cell.active ? "✦" : cell.busy ? "✧" : "·"
                    color: cell.active ? "#9FB8FF" : cell.busy ? "#E6E9F5" : "#9AA3BF"
                    font.pixelSize: Math.min(cell.height, cell.width) * (cell.active ? 0.42 : 0.32)

                    layer.enabled: cell.active
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: true
                        shadowEnabled: true
                        shadowColor: "#CC9FB8FF"
                        shadowBlur: 0.8
                        blurMax: 16
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 0
                    }
                }

                Rectangle {
                    // Dashed link to the next workspace with windows.
                    visible: root.look === "constellation" && (cell.busy || cell.active) && cell.index < root.slots.length - 1 && grid.columns > 1
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -cell.height * 0.1
                    x: parent.width * 0.62
                    width: parent.width * 0.76 + grid.spacing
                    height: 1
                    color: "transparent"

                    Row {
                        spacing: 4
                        Repeater {
                            model: Math.floor(parent.parent.width / 7)
                            Rectangle {
                                width: 3
                                height: 1
                                color: Qt.alpha("#9FB8FF", 0.6)
                            }
                        }
                    }
                }

                // The number.
                Item {
                    anchors.fill: parent

                    // facade: unlit segments, busy dim, active lit.
                    HeroText {
                        visible: root.look === "facade"
                        anchors.centerIn: parent
                        text: cell.modelData.name
                        pixelSize: cell.figureSize
                        color: cell.urgent ? "#FFB547" : cell.active ? root.theme.color.ink : cell.busy ? Qt.alpha(root.theme.color.ink, 0.45) : root.theme.color.ghost
                    }

                    ThemedText {
                        visible: root.look !== "facade"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: root.look === "constellation" ? cell.height * 0.26 : root.look === "modulaire" || root.look === "matrix" ? cell.height * 0.08 : 0
                        text: cell.modelData.name
                        font.family: root.look === "classic" ? root.theme.font.display : root.look === "modulaire" ? root.theme.font.family : root.look === "matrix" ? root.theme.font.display : root.theme.font.family
                        font.weight: root.look === "constellation" ? Font.Light : root.look === "modulaire" ? Font.DemiBold : Font.Bold
                        font.pixelSize: root.look === "constellation" ? cell.figureSize * 0.55 : root.look === "modulaire" ? Math.min(22, cell.figureSize * 0.7) : cell.figureSize * (root.look === "matrix" ? 0.75 : 1)
                        color: root.look === "classic" ? (cell.active ? root.theme.color.onAccent : root.theme.color.ink)
                            : root.look === "modulaire" ? (cell.active ? "#111111" : "#DDDDDD")
                            : root.look === "matrix" ? (cell.active || cell.busy ? root.theme.color.ink : root.theme.color.soft)
                            : root.theme.color.soft
                    }
                }

                // classic: a dot per window.
                Row {
                    visible: root.look === "classic"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: cell.height * 0.1
                    spacing: 4

                    Repeater {
                        model: Math.min(cell.windows, 6)

                        Rectangle {
                            width: Math.max(5, cell.height * 0.05)
                            height: width
                            radius: width / 2
                            color: cell.active ? root.theme.color.onAccent : root.theme.color.soft
                        }
                    }
                }
            }
        }
    }
}
