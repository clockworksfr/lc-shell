import QtQuick
import QtQuick.Effects
import Quickshell
import qs.theme

// A linear gauge (0..1) in the theme's language: classic pill,
// constellation comet (2 px line, glowing head), facade bargraph cells
// (unlit = ghost), modulaire LED ladder (green / yellow / red), matrix
// 5 px dots. Red above `alarm`.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"

    property real value: 0
    property real alarm: 0.9
    property color color: value > alarm ? theme.color.urgent : theme.color.accent
    readonly property real v: Math.max(0, Math.min(1, value))

    implicitHeight: look === "modulaire" ? 10 : look === "facade" ? 10 : look === "matrix" ? 6 : 6

    // Classic.
    Rectangle {
        visible: root.look === "classic"
        anchors.fill: parent
        radius: height / 2
        color: root.theme.color.surface3

        Rectangle {
            width: parent.width * root.v
            height: parent.height
            radius: parent.radius
            color: root.color
            Behavior on width {
                NumberAnimation {
                    duration: 300
                }
            }
        }
    }

    // Constellation: a comet.
    Item {
        visible: root.look === "constellation"
        anchors.fill: parent

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 1
            color: Qt.alpha(root.theme.color.ink, 0.15)
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * root.v
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: root.color
                }
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * root.v - width / 2
            width: 8
            height: 8
            radius: 4
            color: root.color

            Rectangle {
                anchors.centerIn: parent
                width: 18
                height: 18
                radius: 9
                color: Qt.alpha(root.color, 0.22)
            }
        }
    }

    // Facade / modulaire / matrix: discrete cells.
    Row {
        visible: root.look === "facade" || root.look === "modulaire" || root.look === "matrix"
        anchors.fill: parent
        spacing: root.look === "matrix" ? 3 : 2
        // Matrix: lit dots glow (theme glow, dark only).
        layer.enabled: root.look === "matrix" && Qt.color(root.theme.color.glow ?? "#00000000").a > 0
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowColor: root.theme.color.glow ?? "transparent"
            shadowBlur: 0.5
            blurMax: 10
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Repeater {
            id: cells

            model: root.look === "facade" ? Math.max(4, Math.floor(root.width / 9)) : root.look === "modulaire" ? Math.max(4, Math.floor(root.width / 12)) : Math.max(4, Math.floor(root.width / 8))

            Rectangle {
                required property int index
                readonly property int count: cells.count
                readonly property real at: (index + 0.5) / Math.max(1, count)
                readonly property bool lit: at <= root.v
                width: root.look === "matrix" ? 5 : (root.width - parent.spacing * (count - 1)) / Math.max(1, count)
                height: root.look === "matrix" ? 5 : root.height
                anchors.verticalCenter: parent.verticalCenter
                radius: root.look === "matrix" ? 2.5 : root.look === "modulaire" ? height / 2 : 1
                color: root.look === "modulaire"
                    ? (lit ? (at > 0.9 ? root.theme.color.urgent : at > 0.7 ? root.theme.color.warn : root.theme.color.ok) : Qt.alpha(root.theme.color.ink, 0.08))
                    : lit ? root.color : (root.look === "facade" ? root.theme.color.ghost : Qt.alpha(root.theme.color.ink, 0.12))
            }
        }
    }
}
