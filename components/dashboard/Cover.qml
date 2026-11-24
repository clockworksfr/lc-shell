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

    // Modulaire ("screwed"): the art in a recessed black bezel, like the
    // module's screens (inner shadow, glass sheen on top), four small flat
    // screws on the bezel's corners.
    readonly property real bezel: look === "screwed" ? Math.max(6, Math.round(size * 0.07)) : 0
    Rectangle {
        visible: root.look === "screwed"
        anchors.fill: parent
        radius: 6
        color: "#111212"
        border.width: 1
        border.color: "#14FFFFFF"

        Repeater {
            model: 4

            Rectangle {
                required property int index
                readonly property real inset: root.bezel / 2
                width: Math.max(4, Math.min(7, root.bezel * 0.6))
                height: width
                radius: width / 2
                x: index % 2 === 0 ? inset - width / 2 : root.size - inset - width / 2
                y: index < 2 ? inset - height / 2 : root.size - inset - height / 2
                color: "#8A8F92"
            }
        }
    }

    ClippingRectangle {
        id: art

        anchors.centerIn: parent
        width: root.look === "disc" ? root.size * 0.82 : root.look === "inset" ? root.size - 12 : root.look === "screwed" ? root.size - 2 * root.bezel : root.size
        height: width
        radius: root.look === "square" ? root.theme.radius.tile : root.look === "inset" ? 2 : root.look === "screwed" ? 2 : width / 2
        color: root.theme.color.surface2

        // No art (yet): a soft mint placeholder (design "Média"); the disc
        // keeps its own dark body.
        Rectangle {
            anchors.fill: parent
            visible: image.status !== Image.Ready && root.look !== "disc"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#D9EFE6"
                }
                GradientStop {
                    position: 0.45
                    color: "#5FA58E"
                }
                GradientStop {
                    position: 1
                    color: "#1D4A42"
                }
            }
        }

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

    // Modulaire: the screen's inner shadow and a glass sheen over the art.
    Repeater {
        model: root.look === "screwed" ? 3 : 0

        Rectangle {
            required property int index
            anchors.fill: art
            anchors.margins: index * 2
            radius: Math.max(0, 2 - index)
            color: "transparent"
            border.width: 2
            border.color: Qt.alpha("black", [0.55, 0.28, 0.1][index])
        }
    }
    Rectangle {
        visible: root.look === "screwed"
        anchors.fill: art
        radius: art.radius
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#22FFFFFF"
            }
            GradientStop {
                position: 0.35
                color: "transparent"
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
            // A fixed 7 px dot, placed once, scaled with the level (3 → 7 px):
            // a new frame changes its scale, color and opacity only.
            width: 7
            height: 7
            radius: 3.5
            x: root.size / 2 + Math.cos(angle) * (root.size / 2 - 3) - 3.5
            y: root.size / 2 + Math.sin(angle) * (root.size / 2 - 3) - 3.5
            scale: (3 + level * 4) / 7
            // Ink only: Matrix keeps red for alerts, play and the progress head.
            color: root.theme.color.ink
            opacity: 0.45 + level * 0.55
            // (No width animation: 56 of them running 30 times a second cost
            // more than the spectrum; only the width moved, the dots went
            // oval for 60 ms.)
        }
    }
}
