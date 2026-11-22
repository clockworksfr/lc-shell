import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.theme

// A round gauge (0..1) in the theme's language (style.ring): "arc" (thick
// 270° arc), "orbit" (thin circle, gradient arc, a planet at the value),
// "knob" (rotary knob: ticks, white index), "dots" (36 dots, lit ones
// glowing), "vu" (falls back to "arc" outside audio). Children sit in the
// center.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.ring ?? "arc"

    property real value: 0
    property real alarm: 0.9
    property color color: value > alarm ? theme.color.urgent : theme.color.accent
    readonly property real v: Math.max(0, Math.min(1, value))
    readonly property real size: Math.min(width, height)
    readonly property real stroke: Math.max(3, size * (look === "orbit" ? 0.025 : 0.08))
    default property alias content: center.data

    // Arc / orbit / vu: track and value.
    Shape {
        anchors.centerIn: parent
        width: root.size
        height: root.size
        visible: root.look === "arc" || root.look === "orbit" || root.look === "vu"
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.look === "orbit" ? Qt.alpha(root.theme.color.ink, 0.14) : root.theme.color.surface3
            strokeWidth: root.look === "orbit" ? 1 : root.stroke
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - root.stroke
                radiusY: radiusX
                startAngle: root.look === "orbit" ? 0 : 135
                sweepAngle: root.look === "orbit" ? 360 : 270
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: root.color
            strokeWidth: root.stroke
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - root.stroke
                radiusY: radiusX
                startAngle: root.look === "orbit" ? -90 : 135
                sweepAngle: (root.look === "orbit" ? 360 : 270) * root.v
            }
        }
    }

    // Orbit: the planet.
    Rectangle {
        visible: root.look === "orbit"
        readonly property real angle: (-90 + 360 * root.v) * Math.PI / 180
        readonly property real r: root.size / 2 - root.stroke
        width: Math.max(8, root.size * 0.07)
        height: width
        radius: width / 2
        x: root.width / 2 + Math.cos(angle) * r - width / 2
        y: root.height / 2 + Math.sin(angle) * r - height / 2
        color: root.color

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 2.4
            height: width
            radius: width / 2
            color: Qt.alpha(root.color, 0.2)
        }
    }

    // Dots: 36 around, lit up to the value.
    Repeater {
        model: root.look === "dots" ? 36 : 0

        Rectangle {
            required property int index
            readonly property real angle: (135 + 270 * index / 35) * Math.PI / 180
            readonly property real r: root.size / 2 - width
            readonly property bool lit: index / 35 <= root.v && root.v > 0
            width: Math.max(4, root.size * 0.045)
            height: width
            radius: width / 2
            x: root.width / 2 + Math.cos(angle) * r - width / 2
            y: root.height / 2 + Math.sin(angle) * r - height / 2
            // Beyond 90 %: the signal color (Matrix red).
            color: lit ? (index / 35 > 0.9 ? (root.theme.color.signal ?? root.color) : root.color) : Qt.alpha(root.theme.color.ink, 0.12)
        }
    }

    // Knob: body, ticks, index.
    Item {
        visible: root.look === "knob"
        anchors.centerIn: parent
        width: root.size
        height: root.size

        Repeater {
            model: 11

            Rectangle {
                required property int index
                readonly property real angle: (135 + 27 * index) * Math.PI / 180
                readonly property real r: root.size / 2 - 3
                width: 2
                height: root.size * 0.07
                x: root.size / 2 + Math.cos(angle) * r - width / 2
                y: root.size / 2 + Math.sin(angle) * r - height / 2
                rotation: 135 + 27 * index + 90
                color: root.theme.color.soft
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.size * 0.7
            height: width
            radius: width / 2
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.lighter(root.theme.color.surface3, 1.6)
                }
                GradientStop {
                    position: 1
                    color: root.theme.color.surface3
                }
            }
            border.width: 1
            border.color: Qt.alpha("black", 0.5)
            rotation: -135 + 270 * root.v

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.06
                width: Math.max(2, parent.width * 0.05)
                height: parent.height * 0.3
                radius: width / 2
                color: "white"
            }
        }
    }

    Item {
        id: center
        anchors.centerIn: parent
        width: root.size * 0.7
        height: root.size * 0.7
    }
}
