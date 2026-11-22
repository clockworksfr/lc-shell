import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme

// Album art in the theme's language (style.cover): "square" (rounded),
// "sphere" (a round planet with a halo), "disc" (round, turning while
// playing, a ring of dots following the sound), "inset" (square, in a
// recessed black frame: facade), "screwed" (square, 3 px corners, screwed
// to the panel: modulaire),
// "none" (no art: the theme shows text in its display instead; zero size).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.cover ?? "square"
    readonly property bool shown: look !== "none"

    property string source
    property real size: 120
    // Playing: the disc turns and its ring of dots follows the sound.
    property bool playing: false

    // The spectrum feeds the ring (disc only, while playing).
    readonly property bool listening: look === "disc" && playing
    onListeningChanged: listening ? Spectrum.refCount++ : Spectrum.refCount--
    Component.onDestruction: if (listening) Spectrum.refCount--

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

    // Facade: recessed frame (black edge, light lower bevel).
    Rectangle {
        visible: root.look === "inset"
        anchors.fill: parent
        radius: 4
        color: root.theme.color.screen ?? "#030505"
        border.width: 2
        border.color: "black"

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 2
            height: 1
            color: Qt.alpha("white", 0.12)
        }
    }

    // Modulaire: a plate with four screws.
    Rectangle {
        visible: root.look === "screwed"
        anchors.fill: parent
        radius: 3
        color: Qt.darker(root.theme.color.surface, 1.15)
        border.width: 1
        border.color: Qt.alpha("black", 0.4)

        Repeater {
            model: 4

            Rectangle {
                required property int index
                width: 5
                height: 5
                radius: 2.5
                x: index % 2 === 0 ? 0.5 : root.size - 5.5
                y: index < 2 ? 0.5 : root.size - 5.5
                color: Qt.darker(root.theme.color.surface, 1.5)
            }
        }
    }

    ClippingRectangle {
        id: art

        anchors.centerIn: parent
        width: root.look === "disc" ? root.size * 0.82 : root.look === "inset" || root.look === "screwed" ? root.size - 12 : root.size
        height: width
        radius: root.look === "square" ? root.theme.radius.tile : root.look === "inset" ? 2 : root.look === "screwed" ? 3 : width / 2
        color: root.theme.color.surface2

        Image {
            id: image
            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true

            // A record turning (disc).
            RotationAnimator on rotation {
                running: root.look === "disc" && root.playing && !Motion.reduced
                from: 0
                to: 360
                duration: 8000
                loops: Animation.Infinite
            }
        }
    }

    // Ring of dots (disc).
    Repeater {
        model: root.look === "disc" ? 56 : 0

        Rectangle {
            required property int index
            readonly property real angle: index / 56 * Math.PI * 2
            // The band under this dot (the ring is mirrored: bass at the top).
            readonly property real level: {
                const v = Spectrum.values;
                if (!root.listening || !v.length)
                    return 0;
                const k = index < 28 ? index : 55 - index;
                return v[Math.min(v.length - 1, Math.floor(k * v.length / 28))] ?? 0;
            }
            readonly property real r: root.size / 2 - 3 - level * root.size * 0.04
            readonly property real d: 3 + level * 4
            width: d
            height: d
            radius: d / 2
            x: root.size / 2 + Math.cos(angle) * (root.size / 2 - 3) - d / 2
            y: root.size / 2 + Math.sin(angle) * (root.size / 2 - 3) - d / 2
            color: level > 0.75 ? (root.theme.color.signal ?? root.theme.color.ink) : root.theme.color.ink
            opacity: 0.45 + level * 0.55

            Behavior on width {
                NumberAnimation {
                    duration: 60
                }
            }
        }
    }
}
