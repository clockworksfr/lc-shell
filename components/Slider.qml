import QtQuick
import Quickshell
import qs.theme

// Horizontal slider. `value` is not written by the slider itself:
// handle `moved(value)` and update the source (e.g. PipeWire), which then
// flows back through the binding.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property real value: 0
    property real from: 0
    property real to: 1
    property real wheelStep: 0.05
    property bool dimmed: false

    signal moved(real value)

    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / (to - from)))

    implicitWidth: 200
    implicitHeight: 20

    function valueAt(x: real): real {
        return from + Math.max(0, Math.min(1, x / width)) * (to - from);
    }

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: root.theme.radius.full
        color: root.theme.color.bg

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: root.dimmed ? root.theme.color.soft : root.theme.color.accent
        }
    }

    Rectangle {
        x: track.width * root.ratio - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: root.theme.radius.full
        // The handle: the theme's signal color (Matrix red), else ink.
        color: root.dimmed ? root.theme.color.soft : root.theme.color.signal ?? root.theme.color.ink
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.moved(root.valueAt(mouse.x))
        onPositionChanged: mouse => {
            if (pressed)
                root.moved(root.valueAt(mouse.x));
        }
        onWheel: wheel => root.moved(Math.max(root.from, Math.min(root.to, root.value + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep))))
    }
}
