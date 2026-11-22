import QtQuick
import qs.components

// A pill of the manager's header: a board (all, pinned, a tag: `dot` in
// its color) or a kind filter (icon only, `tip` as its accessible name).
Rectangle {
    id: root

    property var theme
    property string text
    property string icon
    property string dot
    property string tip
    property bool selected: false

    signal clicked

    anchors.verticalCenter: parent?.verticalCenter
    implicitWidth: row.implicitWidth + theme.space.m * 2
    width: implicitWidth
    height: (parent?.height ?? 34) - 4
    radius: theme.radius.full
    color: selected ? theme.color.accent : area.containsMouse ? theme.color.surface3 : theme.color.surface2
    Accessible.name: tip || text

    Row {
        id: row

        anchors.centerIn: parent
        spacing: root.theme.space.xs

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.dot
            width: 10
            height: 10
            radius: 5
            color: root.dot || "transparent"
            border.width: root.selected ? 1 : 0
            border.color: root.theme.color.onAccent
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.icon
            name: root.icon
            size: 16
            color: root.selected ? root.theme.color.onAccent : root.theme.color.ink
        }

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.text
            text: root.text
            font.pixelSize: root.theme.font.sizeS
            color: root.selected ? root.theme.color.onAccent : root.theme.color.ink
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
