import QtQuick
import qs.components

// Round icon button of the manager's header; `active` = toggled on.
Rectangle {
    id: root

    property var theme
    property string icon
    property string tip
    property bool active: false

    signal clicked

    width: height
    height: parent?.height ?? 34
    radius: theme.radius.full
    color: active ? Qt.alpha(theme.color.warn, 0.25) : area.containsMouse ? theme.color.surface3 : "transparent"
    Accessible.name: tip

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: 20
        color: root.active ? root.theme.color.warn : root.theme.color.ink
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
