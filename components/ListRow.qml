import QtQuick
import Quickshell
import qs.theme

// Clickable row for panels: title, optional subtitle and trailing text.
// At least `theme.hit` tall, so it stays usable on touch screens.
Rectangle {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string title
    property string subtitle
    property string trailing
    property bool selected: false
    property bool dimmed: false

    signal clicked

    width: parent?.width ?? 0
    implicitHeight: Math.max(theme.hit, column.implicitHeight + theme.space.s * 2)
    radius: theme.radius.control
    color: area.pressed ? theme.color.surface3 : area.containsMouse || selected ? theme.color.surface2 : "transparent"

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: trailingText.left
        anchors.leftMargin: root.theme.space.s
        anchors.rightMargin: root.theme.space.s
        anchors.verticalCenter: parent.verticalCenter

        ThemedText {
            width: parent.width
            text: root.title
            color: root.dimmed ? root.theme.color.soft : root.theme.color.ink
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
        }

        ThemedText {
            width: parent.width
            visible: !!root.subtitle
            text: root.subtitle
            color: root.theme.color.soft
            font.pixelSize: root.theme.font.sizeS
            elide: Text.ElideRight
        }
    }

    ThemedText {
        id: trailingText

        anchors.right: parent.right
        anchors.rightMargin: root.theme.space.s
        anchors.verticalCenter: parent.verticalCenter
        text: root.trailing
        color: root.theme.color.soft
        font.pixelSize: root.theme.font.sizeS
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
