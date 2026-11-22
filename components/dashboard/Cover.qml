import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.theme

// Album art in the theme's language (style.cover): "square" (rounded),
// "sphere" (a round planet with a halo), "disc" (round, ring of dots),
// "none" (no art: the theme shows text in its display instead; zero size).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.cover ?? "square"
    readonly property bool shown: look !== "none"

    property string source
    property real size: 120

    implicitWidth: shown ? size : 0
    implicitHeight: shown ? size : 0
    visible: shown

    // Halo (sphere).
    Rectangle {
        visible: root.look === "sphere"
        anchors.centerIn: parent
        width: root.size * 1.16
        height: width
        radius: width / 2
        color: Qt.alpha(root.theme.color.accent, 0.16)
    }

    ClippingRectangle {
        anchors.centerIn: parent
        width: root.look === "disc" ? root.size * 0.82 : root.size
        height: width
        radius: root.look === "square" ? root.theme.radius.tile : width / 2
        color: root.theme.color.surface2

        Image {
            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    // Ring of dots (disc).
    Repeater {
        model: root.look === "disc" ? 40 : 0

        Rectangle {
            required property int index
            readonly property real angle: index / 40 * Math.PI * 2
            readonly property real r: root.size / 2 - 3
            width: 3
            height: 3
            radius: 1.5
            x: root.size / 2 + Math.cos(angle) * r - 1.5
            y: root.size / 2 + Math.sin(angle) * r - 1.5
            color: root.theme.color.ink
            opacity: 0.6
        }
    }
}
