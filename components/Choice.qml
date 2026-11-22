import QtQuick
import Quickshell
import qs.theme

// Segmented choice: one of a few options, side by side.
// model: [{ value, label }]; emits picked(value), doesn't change `value`.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property var model: []
    property var value

    signal picked(var value)

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(theme.hit, 32)

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radius.control
        color: root.theme.color.surface2
    }

    Row {
        id: row

        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        Repeater {
            model: root.model

            Rectangle {
                required property var modelData
                readonly property bool selected: modelData.value === root.value

                width: Math.max(label.implicitWidth + root.theme.space.m * 2, 48)
                height: parent.height
                radius: root.theme.radius.control - 2
                color: selected ? root.theme.color.accent : area.containsMouse ? root.theme.color.surface3 : "transparent"

                ThemedText {
                    id: label
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: parent.selected ? root.theme.color.onAccent : root.theme.color.ink
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(parent.modelData.value)
                }
            }
        }
    }
}
