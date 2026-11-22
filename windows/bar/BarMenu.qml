import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.settings
import qs.theme

// Right-click menu of the bar: edit the bar, bar settings, settings.
// A popup at the pointer; closes on pick, on Escape-less click outside
// (focus lost) or after leaving it for a moment.
PopupWindow {
    id: root

    required property var host
    readonly property var theme: host?.theme ?? Themes.fallback

    function openAt(x: real, y: real): void {
        visible = false;
        anchor.rect.x = x;
        anchor.rect.y = y;
        anchor.rect.width = 1;
        anchor.rect.height = 1;
        const edge = host.edge;
        anchor.edges = edge === "top" ? Edges.Bottom : edge === "bottom" ? Edges.Top : edge === "left" ? Edges.Right : Edges.Left;
        anchor.gravity = anchor.edges;
        Qt.callLater(() => root.visible = true);
    }

    readonly property var actions: [
        { icon: "edit", label: I18n.tr("bar.menu.edit"), run: () => ShellState.editing = true },
        { icon: "tune", label: I18n.tr("bar.menu.barSettings"), run: () => Settings.open("bar") },
        { icon: "settings", label: I18n.tr("bar.menu.settings"), run: () => Settings.open("appearance") }
    ]

    anchor.window: host
    color: "transparent"
    implicitWidth: 240
    implicitHeight: column.implicitHeight + theme.space.xs * 2

    Rectangle {
        id: frame

        anchors.fill: parent
        radius: root.theme.radius.card
        color: root.theme.color.surface
        border.width: root.theme.border.width
        border.color: root.theme.color.line

        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.96
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.ms(root.theme, "fast", "")
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.ms(root.theme, "fast", "")
                easing.type: Motion.easing(root.theme)
            }
        }

        HoverHandler {
            id: hover
            onHoveredChanged: hovered ? leave.stop() : leave.restart()
        }

        Column {
            id: column

            x: root.theme.space.xs
            y: root.theme.space.xs
            width: parent.width - root.theme.space.xs * 2

            Repeater {
                model: root.actions

                Rectangle {
                    id: row

                    required property var modelData
                    width: column.width
                    height: Math.max(36, root.theme.hit.pointer + 12)
                    radius: root.theme.radius.control
                    color: rowHover.hovered ? Qt.alpha(root.theme.color.accent, 0.14) : "transparent"

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: root.theme.space.s
                        spacing: root.theme.space.s

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: row.modelData.icon
                            size: 18
                            color: root.theme.color.soft
                        }

                        ThemedText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label
                        }
                    }

                    HoverHandler {
                        id: rowHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.visible = false;
                            row.modelData.run();
                        }
                    }
                }
            }
        }
    }

    // Left without picking: closes.
    Timer {
        id: leave
        interval: 900
        onTriggered: root.visible = false
    }
    onVisibleChanged: if (visible) leave.restart()
}
