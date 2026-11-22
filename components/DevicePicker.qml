import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.services
import qs.theme

// Current audio device; a tap unfolds the other devices of the same kind
// (outputs or inputs), a tap on one makes it the default and folds back.
// Touch-sized rows; nothing depends on hover.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string icon: "speaker"
    property list<PwNode> devices
    property PwNode current
    // Text on the right of the current device (volume, "Muted"…).
    property string trailing
    property color trailingColor: theme.color.ink
    property bool expanded: false
    readonly property bool choice: devices.length > 1

    signal picked(PwNode node)

    spacing: 2

    // Folds back when the card closes or the list changes under it.
    onDevicesChanged: if (!choice) expanded = false

    Rectangle {
        width: root.width
        implicitHeight: Math.max(root.theme.hit, head.implicitHeight + root.theme.space.s)
        radius: root.theme.radius.control
        color: root.choice && (headArea.containsMouse || root.expanded) ? root.theme.color.surface2 : "transparent"

        Row {
            id: head
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: root.choice ? root.theme.space.s : 0
            anchors.rightMargin: root.choice ? root.theme.space.s : 0
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.space.s

            Icon {
                id: kind
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon
                size: root.theme.font.sizeL
                color: root.theme.color.soft
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                width: head.width - kind.width - value.width - (root.choice ? chevron.width + head.spacing : 0) - head.spacing * 2
                text: Audio.nodeName(root.current)
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            ThemedText {
                id: value
                anchors.verticalCenter: parent.verticalCenter
                text: root.trailing
                color: root.trailingColor
                font.features: ({ "tnum": 1 })
            }

            Icon {
                id: chevron
                anchors.verticalCenter: parent.verticalCenter
                visible: root.choice
                name: "expand_more"
                size: root.theme.font.sizeL
                color: root.theme.color.soft
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    NumberAnimation {
                        duration: Motion.ms(root.theme, "fast", "")
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MouseArea {
            id: headArea
            anchors.fill: parent
            enabled: root.choice
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // The other devices, unfolding under the current one.
    Item {
        width: root.width
        height: root.expanded ? list.implicitHeight : 0
        clip: true
        visible: height > 0

        Behavior on height {
            NumberAnimation {
                duration: Motion.ms(root.theme, "base", "")
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: root.devices

                Rectangle {
                    id: row

                    required property PwNode modelData
                    readonly property bool selected: modelData === root.current

                    width: list.width
                    implicitHeight: Math.max(root.theme.hit, name.implicitHeight + root.theme.space.s)
                    radius: root.theme.radius.control
                    color: rowArea.containsMouse ? root.theme.color.surface2 : "transparent"

                    Icon {
                        id: mark
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.space.s
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.selected ? "radio_button_checked" : "radio_button_unchecked"
                        filled: row.selected
                        size: root.theme.font.sizeL
                        color: row.selected ? root.theme.color.accent : root.theme.color.soft
                    }

                    ThemedText {
                        id: name
                        anchors.left: mark.right
                        anchors.leftMargin: root.theme.space.s
                        anchors.right: parent.right
                        anchors.rightMargin: root.theme.space.s
                        anchors.verticalCenter: parent.verticalCenter
                        text: Audio.nodeName(row.modelData)
                        color: row.selected ? root.theme.color.ink : root.theme.color.soft
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!row.selected)
                                root.picked(row.modelData);
                            root.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
