import QtQuick
import Quickshell
import qs.theme

// A push button: optional icon, text; `primary` = filled with the accent.
Rectangle {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string text
    property string icon
    property bool primary: false

    signal clicked

    implicitWidth: row.implicitWidth + theme.space.m * 2
    implicitHeight: Math.max(theme.hit, 32)
    radius: theme.radius.control
    color: primary ? (area.containsMouse ? Qt.lighter(theme.color.accent, 1.08) : theme.color.accent) : (area.containsMouse ? theme.color.surface3 : theme.color.surface2)
    border.width: primary ? 0 : 1
    border.color: theme.color.line
    opacity: enabled ? 1 : 0.5

    Row {
        id: row

        anchors.centerIn: parent
        spacing: root.theme.space.xs

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: !!root.icon
            name: root.icon
            size: 18
            color: root.primary ? root.theme.color.onAccent : root.theme.color.ink
        }

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.primary ? root.theme.color.onAccent : root.theme.color.ink
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
