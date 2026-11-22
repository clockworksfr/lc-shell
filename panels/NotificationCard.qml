import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.i18n
import qs.services
import qs.theme

// One notification: icon/image, app and time, summary, body, actions.
// Click: default action. `popup`: hovering pauses its expiry.
Rectangle {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    required property var entry
    property bool popup: false

    readonly property var notification: NotificationCenter.live[entry.uid] ?? null
    readonly property var actions: (notification?.actions ?? []).filter(a => a.identifier !== "default")
    readonly property bool critical: entry.urgency === NotificationUrgency.Critical

    width: parent?.width ?? 0
    implicitHeight: content.implicitHeight + theme.space.m * 2
    radius: theme.radius.tile
    color: theme.color.surface
    border.width: critical ? 2 : theme.border.width
    border.color: critical ? theme.color.urgent : theme.color.line

    MouseArea {
        anchors.fill: parent
        hoverEnabled: root.popup
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: if (root.popup) NotificationCenter.hold(root.entry.uid, containsMouse)
        onClicked: NotificationCenter.activate(root.entry.uid)
    }

    Row {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.theme.space.m
        spacing: root.theme.space.m

        Item {
            id: iconBox

            readonly property string source: root.entry.image || (root.entry.appIcon ? Quickshell.iconPath(root.entry.appIcon, true) : "")

            visible: !!source
            width: visible ? 36 : 0
            height: 36

            IconImage {
                anchors.fill: parent
                source: iconBox.source
                asynchronous: true
            }
        }

        Column {
            width: parent.width - iconBox.width - (iconBox.visible ? parent.spacing : 0) - close.width - parent.spacing
            spacing: root.theme.space.xs

            ThemedText {
                width: parent.width
                text: [root.entry.appName, I18n.relativeTime(root.entry.time)].filter(s => !!s).join(" · ")
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                text: root.entry.summary
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                visible: !!root.entry.body
                text: root.entry.body
                color: root.theme.color.soft
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: root.popup ? 4 : 8
                elide: Text.ElideRight
            }

            Flow {
                width: parent.width
                visible: root.actions.length > 0
                spacing: root.theme.space.s

                Repeater {
                    model: root.actions

                    Rectangle {
                        required property var modelData

                        width: actionText.implicitWidth + root.theme.space.m * 2
                        height: Math.max(root.theme.hit, 30)
                        radius: root.theme.radius.full
                        color: actionArea.pressed ? root.theme.color.surface3 : root.theme.color.surface2

                        ThemedText {
                            id: actionText
                            anchors.centerIn: parent
                            text: parent.modelData.text
                        }

                        MouseArea {
                            id: actionArea
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NotificationCenter.invoke(root.entry.uid, parent.modelData.identifier)
                        }
                    }
                }
            }
        }

        // Close: dismiss (removes it from history too).
        Item {
            id: close

            width: Math.max(root.theme.hit, 24)
            height: width

            ThemedText {
                anchors.centerIn: parent
                text: "×"
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeL
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationCenter.dismiss(root.entry.uid)
            }
        }
    }
}
