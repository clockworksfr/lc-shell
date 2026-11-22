import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme

// Album art in the theme's language (style.cover): "square" (rounded),
// "sphere" (a round planet with a halo), "disc" (round, turning while
// playing, a ring of dots following the sound),
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

    ClippingRectangle {
        id: art

        anchors.centerIn: parent
        width: root.look === "disc" ? root.size * 0.82 : root.size
        height: width
        radius: root.look === "square" ? root.theme.radius.tile : width / 2
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
                duration: 24000
                loops: Animation.Infinite
            }
        }
    }

    // Ring of dots (disc).
    Repeater {
        model: root.look === "disc" ? 40 : 0

        Rectangle {
            required property int index
            readonly property real angle: index / 40 * Math.PI * 2
            // The band under this dot (the ring is mirrored: bass at the top).
            readonly property real level: {
                const v = Spectrum.values;
                if (!root.listening || !v.length)
                    return 0;
                const k = index < 20 ? index : 39 - index;
                return v[Math.min(v.length - 1, Math.floor(k * v.length / 20))] ?? 0;
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
