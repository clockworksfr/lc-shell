import QtQuick
import Quickshell
import qs.theme

// On/off switch with a label. Like Slider, it doesn't change `checked`
// itself: handle `toggled()` and let the source flow back.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string text
    property bool checked: false
    // Greyed out and inert when false (`enabled` is Item's own).
    property bool available: true

    signal toggled

    width: parent?.width ?? 0
    implicitHeight: Math.max(theme.hit, label.implicitHeight)
    opacity: available ? 1 : 0.5

    ThemedText {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
    }

    Rectangle {
        id: track

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 22
        radius: root.theme.radius.full
        color: root.checked ? root.theme.color.accent : root.theme.color.surface3

        Rectangle {
            x: root.checked ? parent.width - width - 3 : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: root.theme.radius.full
            color: root.checked ? root.theme.color.onAccent : root.theme.color.soft

            Behavior on x {
                NumberAnimation {
                    duration: root.theme.motion.duration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
