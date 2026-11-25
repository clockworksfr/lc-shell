import QtQuick
import Quickshell
import qs.theme

// Horizontal slider. `value` is not written by the slider itself:
// handle `moved(value)` and update the source (e.g. PipeWire), which then
// flows back through the binding. In each theme's language (design
// review): classic a filled track and a ringed handle; constellation a
// hairline and a glowing dot; matrix a track of dots and a red pill;
// facade and modulaire a fader cap on a recessed slot (no fill).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"

    property real value: 0
    property real from: 0
    property real to: 1
    property real wheelStep: 0.05
    property bool dimmed: false

    signal moved(real value)

    readonly property real ratio: Math.max(0, Math.min(1, (value - from) / (to - from)))
    // Façade in cards (design "Hover cards"): a segmented VFD bar, no cap.
    readonly property bool segmented: look === "facade" && !!theme.color.vfd
    readonly property bool fader: (look === "facade" && !segmented) || look === "modulaire"
    readonly property color handleColor: dimmed ? theme.color.soft : theme.color.signal ?? theme.color.ink
    readonly property int dots: Math.max(1, Math.floor((width + 7) / 9))

    implicitWidth: 200
    implicitHeight: segmented ? 22 : look === "matrix" ? 34 : look === "modulaire" ? 30 : look === "classic" ? 22 : 20

    function valueAt(x: real): real {
        return from + Math.max(0, Math.min(1, x / width)) * (to - from);
    }

    // Track (classic, constellation; faders: a slot).
    Rectangle {
        id: track

        visible: root.look !== "matrix" && !root.segmented
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.look === "classic" ? 8 : root.look === "constellation" ? 2 : root.look === "modulaire" ? 12 : root.look === "facade" ? 8 : 6
        radius: root.fader ? 0 : root.theme.radius.full
        // Visible on every card (the background color vanished on dark
        // cards, e.g. a light that's off in Matrix).
        color: root.fader ? Qt.alpha("black", root.look === "modulaire" ? 0.25 : 0.5) : Qt.alpha(root.theme.color.ink, 0.18)

        Rectangle {
            visible: !root.fader
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: root.dimmed ? root.theme.color.soft : root.theme.color.accent
        }
    }

    // Matrix: a track of dots, lit up to the value.
    Row {
        visible: root.look === "matrix"
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Repeater {
            model: root.look === "matrix" ? root.dots : 0

            Rectangle {
                required property int index
                width: 2
                height: 2
                radius: 1
                color: (index + 0.5) / root.dots <= root.ratio ? (root.dimmed ? root.theme.color.soft : root.theme.color.ink) : root.theme.color.surface3
            }
        }
    }

    // Façade cards: VFD cells, 7 px with 3 px gaps, lit up to the value.
    Row {
        visible: root.segmented
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Repeater {
            model: root.segmented ? Math.max(1, Math.floor((root.width + 3) / 10)) : 0

            Rectangle {
                required property int index
                readonly property int cells: Math.max(1, Math.floor((root.width + 3) / 10))
                width: 7
                height: Math.min(root.height, 22)
                radius: 1
                color: (index + 0.5) / cells <= root.ratio ? (root.dimmed ? Qt.alpha(root.theme.color.vfd, 0.4) : root.theme.color.vfd) : Qt.alpha(root.theme.color.vfd ?? "#6EF3D6", 0.085)
            }
        }
    }

    // Handle.
    Item {
        id: handle
        visible: !root.segmented

        readonly property real w: root.look === "matrix" ? 16 : root.look === "modulaire" ? 28 : root.look === "facade" ? 30 : root.look === "classic" ? 22 : 12
        readonly property real h: root.look === "matrix" ? 34 : root.look === "modulaire" ? 30 : root.look === "facade" ? 18 : w
        x: root.width * root.ratio - w / 2
        anchors.verticalCenter: parent.verticalCenter
        width: w
        height: h

        // Constellation: a halo.
        Rectangle {
            visible: root.look === "constellation"
            anchors.centerIn: parent
            width: 32
            height: 32
            radius: 16
            color: Qt.alpha(root.theme.color.accent, 0.22)
        }

        Rectangle {
            anchors.fill: parent
            radius: root.look === "matrix" ? 8 : root.fader ? 3 : width / 2
            color: root.look === "constellation" ? "white" : root.handleColor
            // Classic: a ring in the surface color around the handle.
            border.width: root.look === "classic" ? 3 : 0
            border.color: root.theme.color.surface
            gradient: root.fader ? capGradient : null

            Gradient {
                id: capGradient
                GradientStop {
                    position: 0
                    color: root.look === "facade" ? "#5A5E61" : "#777C80"
                }
                GradientStop {
                    position: 1
                    color: root.look === "facade" ? "#3A3E41" : "#45494C"
                }
            }

            // Fader: the cap's grip line and its shadowed bottom edge.
            Rectangle {
                visible: root.fader
                anchors.centerIn: parent
                width: parent.width - 8
                height: 2
                color: root.dimmed ? Qt.alpha("#E9E7E1", 0.4) : "#E9E7E1"
            }
            Rectangle {
                visible: root.fader
                anchors.bottom: parent.bottom
                x: 1
                width: parent.width - 2
                height: 3
                color: "#70000000"
            }
        }
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
