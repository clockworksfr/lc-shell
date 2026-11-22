import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Where notifications pop up (picked on a screen diagram), do not disturb.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string position: Config.get("notifications.position") ?? "top-right"

    spacing: theme.space.s

    Section {
        title: I18n.tr("notif.title")

        Field {
            label: I18n.tr("settings.notifPosition")
            hint: I18n.tr(`settings.position.${root.position}`)

            // A screen with its 6 spots (3 × 2).
            Rectangle {
                width: 180
                height: 104
                radius: root.theme.radius.control
                color: root.theme.color.surface
                border.width: 1
                border.color: root.theme.color.line

                Grid {
                    anchors.fill: parent
                    anchors.margins: 6
                    columns: 3
                    rows: 2
                    columnSpacing: 4
                    rowSpacing: 4

                    Repeater {
                        model: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right"]

                        Item {
                            id: spot

                            required property string modelData
                            readonly property bool chosen: root.position === modelData

                            width: (parent.width - 8) / 3
                            height: (parent.height - 4) / 2

                            Rectangle {
                                // The popup: at the spot's side and edge.
                                width: parent.width * 0.78
                                height: 18
                                radius: 4
                                x: spot.modelData.endsWith("left") ? 0 : spot.modelData.endsWith("right") ? parent.width - width : (parent.width - width) / 2
                                y: spot.modelData.startsWith("top") ? 0 : parent.height - height
                                color: spot.chosen ? root.theme.color.accent : spotArea.containsMouse ? root.theme.color.surface3 : root.theme.color.surface2
                                border.width: spot.chosen ? 0 : 1
                                border.color: root.theme.color.line
                            }

                            MouseArea {
                                id: spotArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.set("notifications.position", spot.modelData)
                            }
                        }
                    }
                }
            }
        }

        Field {
            label: I18n.tr("notif.dnd")
            hint: I18n.tr("settings.dndHint")
            Switch {
                width: 60
                checked: NotificationCenter.dnd
                onToggled: NotificationCenter.setDnd(!checked)
            }
        }
    }
}
