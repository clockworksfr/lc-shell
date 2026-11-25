import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Color of a room or a light: a hue wheel (saturation
// toward the center; Matrix: rings of dots), white from 2200 to 6500 K,
// favorites. Sends while dragging (the service throttles) and on release.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"

    property string title
    property color current: "#FFB46B"

    signal colorPicked(string hex)
    signal whitePicked(int kelvin)

    function hex(c: color): string {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0");
        return `#${h(c.r)}${h(c.g)}${h(c.b)}`;
    }

    Row {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 40

        // The wheel.
        Item {
            id: wheelBox

            readonly property real size: Math.min(parent.height, 360)
            property real hue: root.current.hsvHue < 0 ? 0 : root.current.hsvHue
            property real sat: root.current.hsvSaturation

            width: size
            height: parent.height

            Canvas {
                id: wheel

                anchors.centerIn: parent
                width: wheelBox.size
                height: wheelBox.size
                onPaint: {
                    const ctx = getContext("2d");
                    const r = width / 2;
                    ctx.reset();
                    if (root.look === "matrix") {
                        // Three rings of dots: saturation 100, 60, 30 %.
                        const rings = [[24, 1, 0.9], [18, 0.6, 0.64], [12, 0.3, 0.38]];
                        for (const [n, s, k] of rings)
                            for (let i = 0; i < n; i++) {
                                const a = i / n * Math.PI * 2;
                                ctx.fillStyle = Qt.hsva(i / n, s, 1, 1);
                                ctx.beginPath();
                                ctx.arc(r + Math.cos(a) * r * k, r + Math.sin(a) * r * k, r * 0.055, 0, Math.PI * 2);
                                ctx.fill();
                            }
                        return;
                    }
                    // Hue around (red east, clockwise), white toward the center.
                    for (let i = 0; i < 360; i++) {
                        ctx.beginPath();
                        ctx.moveTo(r, r);
                        ctx.arc(r, r, r, (i - 0.6) * Math.PI / 180, (i + 0.6) * Math.PI / 180);
                        ctx.closePath();
                        ctx.fillStyle = Qt.hsva(i / 360, 1, 1, 1);
                        ctx.fill();
                    }
                    const g = ctx.createRadialGradient(r, r, 0, r, r, r);
                    g.addColorStop(0, "rgba(255,255,255,1)");
                    g.addColorStop(1, "rgba(255,255,255,0)");
                    ctx.fillStyle = g;
                    ctx.beginPath();
                    ctx.arc(r, r, r, 0, Math.PI * 2);
                    ctx.fill();
                }
                Component.onCompleted: requestPaint()
            }

            // Marker.
            Rectangle {
                readonly property real a: wheelBox.hue * Math.PI * 2
                readonly property real d: wheelBox.sat * wheelBox.size / 2 * (root.look === "matrix" ? 0.9 : 1)
                width: 30
                height: 30
                radius: 15
                x: wheel.x + wheelBox.size / 2 + Math.cos(a) * d - 15
                y: wheel.y + wheelBox.size / 2 + Math.sin(a) * d - 15
                color: Qt.hsva(wheelBox.hue, wheelBox.sat, 1, 1)
                border.width: 3
                border.color: root.look === "matrix" ? (root.theme.color.signal ?? "white") : "white"
            }

            MouseArea {
                anchors.fill: wheel
                cursorShape: Qt.CrossCursor
                function pick(mouse: var, done: bool): void {
                    const r = wheel.width / 2;
                    const dx = mouse.x - r, dy = mouse.y - r;
                    let a = Math.atan2(dy, dx) / (Math.PI * 2);
                    if (a < 0)
                        a += 1;
                    wheelBox.hue = a;
                    wheelBox.sat = Math.min(1, Math.hypot(dx, dy) / r / (root.look === "matrix" ? 0.9 : 1));
                    root.colorPicked(root.hex(Qt.hsva(wheelBox.hue, wheelBox.sat, 1, 1)));
                }
                onPressed: mouse => pick(mouse, false)
                onPositionChanged: mouse => pick(mouse, false)
                onReleased: mouse => pick(mouse, true)
            }
        }

        Column {
            width: parent.width - wheelBox.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22

            Row {
                spacing: 14

                Rectangle {
                    width: 56
                    height: 56
                    radius: root.look === "facade" ? 4 : 28
                    color: root.current
                    border.width: 1
                    border.color: root.theme.color.line
                }

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.title
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
            }

            ThemedText {
                label: true
                text: I18n.tr("hue.white")
                color: root.theme.color.soft
                font.pixelSize: 14
            }

            // 2200 K (warm) → 6500 K (cold).
            Item {
                width: parent.width
                height: 44

                Rectangle {
                    id: whiteBar
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 14
                    radius: 7
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: "#FF9A3C"
                        }
                        GradientStop {
                            position: 0.3
                            color: "#FFD8A8"
                        }
                        GradientStop {
                            position: 0.6
                            color: "#FFF6EC"
                        }
                        GradientStop {
                            position: 0.85
                            color: "#D6ECFF"
                        }
                        GradientStop {
                            position: 1
                            color: "#A9CCFF"
                        }
                    }
                }

                Rectangle {
                    id: whiteKnob
                    property real ratio: 0.2
                    anchors.verticalCenter: parent.verticalCenter
                    x: ratio * (parent.width - width)
                    width: 18
                    height: 34
                    radius: 9
                    color: root.theme.color.signal ?? root.theme.color.accent
                    border.width: 2
                    border.color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function pick(mouse: var): void {
                        whiteKnob.ratio = Math.max(0, Math.min(1, mouse.x / width));
                        root.whitePicked(Math.round((2200 + whiteKnob.ratio * 4300) / 50) * 50);
                    }
                    onPressed: mouse => pick(mouse)
                    onPositionChanged: mouse => pick(mouse)
                }
            }

            Row {
                width: parent.width

                ThemedText {
                    width: parent.width / 2
                    text: I18n.tr("hue.warm")
                    color: root.theme.color.soft
                    font.pixelSize: 13
                }

                ThemedText {
                    width: parent.width / 2
                    horizontalAlignment: Text.AlignRight
                    text: I18n.tr("hue.cold")
                    color: root.theme.color.soft
                    font.pixelSize: 13
                }
            }

            ThemedText {
                label: true
                text: I18n.tr("hue.favorites")
                color: root.theme.color.soft
                font.pixelSize: 14
            }

            Row {
                spacing: 18

                Repeater {
                    model: HueBridge.favorites

                    HueParts.Swatch {
                        required property var modelData
                        size: 52
                        swatchColor: modelData.color
                        onTapped: root.colorPicked(modelData.color)
                    }
                }
            }
        }
    }
}
