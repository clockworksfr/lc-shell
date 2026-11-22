import QtQuick
import Quickshell
import qs.components
import qs.theme

// A touch button in the theme's language: classic round (accent when
// primary), constellation round with a gradient, facade hardware key with
// a LED (lit when primary) and its legend under, modulaire square key
// (orange when primary), matrix outlined pill (filled with ink when
// primary).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"

    property string icon
    property string legend
    property bool primary: false
    property real size: 56

    signal tapped

    implicitWidth: look === "matrix" ? size * 1.5 : size
    implicitHeight: size + (look === "facade" && legend ? legendText.implicitHeight + 4 : 0)

    Rectangle {
        id: key

        width: root.implicitWidth
        height: root.size
        radius: root.look === "classic" || root.look === "constellation" ? height / 2 : root.look === "matrix" ? height / 2 : 4
        color: area.pressed ? Qt.darker(fill, 1.15) : fill
        border.width: root.look === "matrix" && !root.primary ? 1.5 : root.look === "facade" ? 2 : root.primary ? 0 : 1
        border.color: root.look === "matrix" ? root.theme.color.ink : root.look === "facade" ? "black" : root.theme.color.line
        gradient: root.look === "constellation" && root.primary ? starGradient : null

        readonly property color fill: root.primary
            ? (root.look === "facade" ? root.theme.color.surface3 : root.theme.color.signal ?? root.theme.color.accent)
            : (root.look === "facade" || root.look === "modulaire" ? root.theme.color.surface3 : "transparent")

        Gradient {
            id: starGradient
            GradientStop {
                position: 0
                color: root.theme.color.accent
            }
            GradientStop {
                position: 1
                color: root.theme.color.accent2
            }
        }

        // Facade: the key's LED.
        Rectangle {
            visible: root.look === "facade"
            anchors.horizontalCenter: parent.horizontalCenter
            y: 6
            width: 6
            height: 6
            radius: 3
            color: root.primary ? root.theme.color.urgent : Qt.alpha(root.theme.color.urgent, 0.2)
        }

        Icon {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: root.look === "facade" ? 3 : 0
            name: root.icon
            filled: true
            size: root.size * 0.46
            color: root.primary && root.look !== "facade" ? root.theme.color.onAccent : root.theme.color.ink
        }

        MouseArea {
            id: area
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.tapped()
        }
    }

    ThemedText {
        id: legendText
        visible: root.look === "facade" && !!root.legend
        anchors.horizontalCenter: key.horizontalCenter
        anchors.top: key.bottom
        anchors.topMargin: 4
        label: true
        text: root.legend
        font.pixelSize: 10
        color: root.theme.color.silk ?? root.theme.color.soft
    }
}
