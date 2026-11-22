import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.theme

// A cream VU dial (facade): radial cream face, ticks, red zone from 0 to
// +3 dB, a damped needle (about 0.25 s), "VU" legend and the channel.
// `db` from −20 (rest) to +3.
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    property real db: -20
    property string channel: "L"

    // −20..+3 dB over a 90° sweep (VU scale, roughly logarithmic).
    function angle(value: real): real {
        const v = Math.max(-20, Math.min(3, value));
        const t = Math.pow((v + 20) / 23, 1.6);
        return -45 + 90 * t;
    }

    implicitWidth: 200
    implicitHeight: 130

    Rectangle {
        id: face

        anchors.fill: parent
        radius: 6
        border.width: 2
        border.color: "#111111"
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#FFF3CF"
            }
            GradientStop {
                position: 1
                color: "#CDB57B"
            }
        }
    }

    // Scale.
    Item {
        id: scale

        readonly property real cx: width / 2
        readonly property real cy: height * 1.02
        readonly property real r: Math.min(width * 0.46, height * 0.78)

        anchors.fill: parent

        // Ticks and figures.
        Canvas {
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const marks = [-20, -10, -7, -5, -3, -2, -1, 0, 1, 2, 3];
                const labels = [-20, -10, -5, 0, 3];
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.font = `${Math.max(9, Math.round(scale.r * 0.11))}px "${root.theme.font.family}"`;
                for (const v of marks) {
                    const a = (root.angle(v) - 90) * Math.PI / 180;
                    const long = v % 5 === 0 || v === 3;
                    const r1 = scale.r, r2 = scale.r - (long ? 10 : 6);
                    ctx.strokeStyle = v > 0 ? "#CC3333" : "#222222";
                    ctx.lineWidth = 2;
                    ctx.beginPath();
                    ctx.moveTo(scale.cx + Math.cos(a) * r1, scale.cy + Math.sin(a) * r1);
                    ctx.lineTo(scale.cx + Math.cos(a) * r2, scale.cy + Math.sin(a) * r2);
                    ctx.stroke();
                    if (labels.includes(v)) {
                        ctx.fillStyle = v > 0 ? "#CC3333" : "#222222";
                        const rl = scale.r - 22;
                        ctx.fillText(v > 0 ? `+${v}` : `${v}`, scale.cx + Math.cos(a) * rl, scale.cy + Math.sin(a) * rl);
                    }
                }
            }
        }

        // Red zone (0..+3).
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: "#CC3333"
                strokeWidth: Math.max(3, scale.r * 0.05)
                PathAngleArc {
                    centerX: scale.cx
                    centerY: scale.cy
                    radiusX: scale.r + 6
                    radiusY: scale.r + 6
                    startAngle: root.angle(0) - 90
                    sweepAngle: root.angle(3) - root.angle(0)
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.5
            text: "VU"
            color: "#222222"
            font.family: root.theme.font.family
            font.weight: Font.Bold
            font.pixelSize: Math.max(12, scale.r * 0.18)
        }

        // Needle (damped).
        Rectangle {
            x: scale.cx - width / 2
            y: scale.cy - height
            width: 1.6
            height: scale.r * 1.05
            color: "#111111"
            antialiasing: true
            transformOrigin: Item.Bottom
            rotation: root.angle(root.db)

            Behavior on rotation {
                SmoothedAnimation {
                    velocity: 240
                }
            }
        }
    }

    // Channel strip at the bottom.
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 2
        height: Math.max(14, parent.height * 0.13)
        color: "#2A2A28"

        Text {
            anchors.centerIn: parent
            text: root.channel
            color: "#F1DFAE"
            font.family: root.theme.font.family
            font.weight: Font.Bold
            font.pixelSize: parent.height * 0.65
        }
    }
}
