import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.i18n
import qs.theme

// Active workspace of this screen: window count and a schematic of its
// windows at the screen's proportions (focused one outlined); then the
// screen's other workspaces.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property var workspace: monitor?.activeWorkspace ?? null
    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace === root.workspace).map(t => ({ toplevel: t, info: t.lastIpcObject ?? {} })).filter(w => w.info.at && w.info.size)
    readonly property var workspaces: Hyprland.workspaces.values.filter(ws => ws.id > 0 && ws.monitor === root.monitor).sort((a, b) => a.id - b.id)

    Component.onCompleted: Hyprland.refreshToplevels()

    spacing: theme.space.m

    Item {
        width: parent.width
        implicitHeight: title.implicitHeight

        ThemedText {
            id: title
            text: I18n.tr("card.workspace", { n: root.workspace?.name ?? "?" })
            font.weight: Font.DemiBold
        }

        ThemedText {
            anchors.right: parent.right
            text: I18n.plural("card.windows", root.windows.length)
            color: root.theme.color.soft
        }
    }

    // Schematic of the windows.
    Rectangle {
        id: map

        readonly property real ratio: (root.monitor?.width ?? 16) / Math.max(1, root.monitor?.height ?? 9)
        readonly property real k: width / Math.max(1, root.monitor?.width ?? 1)

        width: parent.width
        height: width / ratio
        radius: root.theme.radius.control
        color: root.theme.color.surface2

        Repeater {
            model: root.windows

            Rectangle {
                required property var modelData
                readonly property bool focused: modelData.toplevel.activated

                x: (modelData.info.at[0] - (root.monitor?.x ?? 0)) * map.k
                y: (modelData.info.at[1] - (root.monitor?.y ?? 0)) * map.k
                width: modelData.info.size[0] * map.k
                height: modelData.info.size[1] * map.k
                radius: 4
                color: root.theme.color.surface3
                border.width: focused ? 2 : 1
                border.color: focused ? root.theme.color.accent : root.theme.color.line
                clip: true

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 6
                    spacing: 2

                    AppIcon {
                        readonly property var entry: DesktopEntries.heuristicLookup(parent.parent.modelData.info.class ?? "")
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !!entry?.icon && parent.parent.height > 40
                        size: 20
                        source: entry?.icon ? Quickshell.iconPath(entry.icon, true) : ""
                    }

                    ThemedText {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.parent.modelData.info.title || parent.parent.modelData.info.class || ""
                        font.pixelSize: root.theme.font.sizeS
                        color: parent.parent.focused ? root.theme.color.ink : root.theme.color.soft
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Flow {
        width: parent.width
        spacing: root.theme.space.xs

        Repeater {
            model: root.workspaces

            Rectangle {
                required property HyprlandWorkspace modelData
                readonly property int count: Hyprland.toplevels.values.filter(t => t.workspace === modelData).length

                width: label.implicitWidth + root.theme.space.m
                height: 26
                radius: root.theme.radius.full
                color: modelData.active ? root.theme.color.accent : area.containsMouse ? root.theme.color.surface3 : root.theme.color.surface2

                ThemedText {
                    id: label
                    anchors.centerIn: parent
                    text: parent.count > 0 ? `${parent.modelData.name} · ${parent.count}` : parent.modelData.name
                    color: parent.modelData.active ? root.theme.color.onAccent : root.theme.color.ink
                    font.pixelSize: root.theme.font.sizeS
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${parent.modelData.id} })`)
                }
            }
        }
    }
}
