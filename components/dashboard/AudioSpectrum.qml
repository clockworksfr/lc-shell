import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import qs.services
import qs.theme

// Live audio spectrum (Spectrum service, cava) in the theme's language:
// classic rounded bars; constellation thin glowing lines; facade
// segmented columns (unlit = ghost); modulaire oscilloscope on a dark
// CRT; matrix columns of dots. `count` bands (resampled).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"
    property int count: 24
    // Matrix and facade light their dots / cells in their ink.
    property color color: theme.style.module === "matrix" || theme.style.module === "facade" ? theme.color.ink : theme.color.accent

    Component.onCompleted: Spectrum.refCount++
    Component.onDestruction: Spectrum.refCount--

    // `count` values from the service's bands (max of each group).
    readonly property var levels: {
        const v = Spectrum.values;
        const out = [];
        for (let i = 0; i < count; i++) {
            if (!v.length) {
                out.push(0);
                continue;
            }
            const a = Math.floor(i * v.length / count);
            const b = Math.max(a + 1, Math.floor((i + 1) * v.length / count));
            let m = 0;
            for (let j = a; j < b; j++)
                m = Math.max(m, v[j] ?? 0);
            out.push(m);
        }
        return out;
    }

    // Bars, lines, segments, dots.
    Row {
        visible: root.look !== "modulaire"
        anchors.fill: parent
        spacing: root.look === "constellation" ? Math.max(3, root.width / root.count * 0.55) : Math.max(2, root.width / root.count * 0.25)

        Repeater {
            model: root.count

            Item {
                id: band

                required property int index
                readonly property real level: root.levels[index] ?? 0
                // Facade: the crest holds 400 ms, then falls.
                property real crest: 0
                property real crestAt: 0
                onLevelChanged: if (root.look === "facade" && level >= crest) {
                    crest = level;
                    crestAt = Date.now();
                }

                Timer {
                    interval: 50
                    repeat: true
                    running: root.look === "facade" && root.visible
                    onTriggered: if (Date.now() - band.crestAt > 400) band.crest = Math.max(band.level, band.crest - 0.04)
                }

                width: (root.width - parent.spacing * (root.count - 1)) / root.count
                height: root.height

                // classic / constellation: a bar or a line.
                Rectangle {
                    visible: root.look === "classic" || root.look === "constellation"
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.look === "constellation" ? 2 : parent.width
                    height: Math.max(2, parent.height * band.level)
                    radius: root.look === "constellation" ? 1 : Math.min(width / 2, 4)
                    color: root.color
                    opacity: root.look === "constellation" ? 0.85 : 1

                    Behavior on height {
                        NumberAnimation {
                            duration: 60
                        }
                    }

                    // Constellation: a glowing head.
                    Rectangle {
                        visible: root.look === "constellation"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -height / 2
                        width: 6
                        height: 6
                        radius: 3
                        color: root.theme.color.accent2 ?? root.color
                    }
                }

                // facade / matrix: stacked cells or dots. The unlit ones
                // are fixed; the lit ones are the same cells clipped to the
                // level from the bottom, so a new frame changes one height
                // per band instead of every cell's color.
                Item {
                    id: stack

                    readonly property int cells: root.look === "facade" ? Math.max(4, Math.min(12, Math.floor(band.height / 6))) : Math.max(4, Math.floor(band.height / 8))
                    readonly property real gap: root.look === "matrix" ? 3 : 2
                    readonly property real cellW: root.look === "matrix" ? Math.min(5, band.width) : band.width
                    readonly property real cellH: root.look === "matrix" ? cellW : Math.max(3, (band.height - (cells - 1) * 2) / cells)
                    // Lit cells: those whose top is under the level.
                    readonly property int lit: band.level > 0.02 ? Math.min(cells, Math.floor(band.level * cells + 0.001 * cells)) : 0
                    readonly property real pitch: cellH + gap

                    visible: root.look === "facade" || root.look === "matrix"
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: cellW
                    height: cells * pitch - gap

                    component Cells: Column {
                        property color cellColor
                        spacing: stack.gap

                        Repeater {
                            model: stack.cells

                            Rectangle {
                                width: stack.cellW
                                height: stack.cellH
                                radius: root.look === "matrix" ? width / 2 : 1
                                color: parent.cellColor
                            }
                        }
                    }

                    Cells {
                        anchors.bottom: parent.bottom
                        cellColor: root.look === "facade" ? root.theme.color.ghost : Qt.alpha(root.theme.color.ink, 0.1)
                    }

                    Item {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: stack.lit > 0 ? stack.lit * stack.pitch - stack.gap : 0
                        clip: true

                        Cells {
                            anchors.bottom: parent.bottom
                            cellColor: root.color
                        }
                    }

                    // Facade: the crest cell, amber, held then falling.
                    Rectangle {
                        readonly property int at: Math.ceil(band.crest * stack.cells)
                        visible: root.look === "facade" && band.crest > 0.04 && at >= 1
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: (at - 1) * stack.pitch
                        width: stack.cellW
                        height: stack.cellH
                        radius: 1
                        color: "#FFB547"
                    }
                }
            }
        }
    }

    // modulaire: an oscilloscope on its own CRT (dark green glass, grid,
    // glowing trace): a waveform rebuilt from the bands (a sum of sines,
    // phase moving at 30 fps).
    property real phase: 0

    Timer {
        interval: 33
        repeat: true
        running: root.look === "modulaire" && root.visible && Spectrum.values.length > 0
        onTriggered: root.phase += 0.35
    }

    Item {
        id: crt

        visible: root.look === "modulaire"
        anchors.fill: parent

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                strokeColor: "#000000"
                strokeWidth: 3
                fillGradient: RadialGradient {
                    centerX: crt.width / 2
                    centerY: crt.height / 2
                    centerRadius: Math.max(crt.width, crt.height) * 0.7
                    focalX: centerX
                    focalY: centerY
                    GradientStop {
                        position: 0
                        color: "#0F2A12"
                    }
                    GradientStop {
                        position: 1
                        color: "#030B04"
                    }
                }
                PathRectangle {
                    x: 1.5
                    y: 1.5
                    width: crt.width - 3
                    height: crt.height - 3
                    radius: 14
                }
            }
        }

        // Graticule every 24 px.
        Canvas {
            anchors.fill: parent
            anchors.margins: 6
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = "rgba(156,255,156,0.08)";
                ctx.lineWidth = 1;
                for (let x = 0; x <= width; x += 24) {
                    ctx.beginPath();
                    ctx.moveTo(x + 0.5, 0);
                    ctx.lineTo(x + 0.5, height);
                    ctx.stroke();
                }
                for (let y = 0; y <= height; y += 24) {
                    ctx.beginPath();
                    ctx.moveTo(0, y + 0.5);
                    ctx.lineTo(width, y + 0.5);
                    ctx.stroke();
                }
            }
        }

        Shape {
            id: trace

            anchors.fill: parent
            anchors.margins: 8
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: true
                shadowEnabled: true
                shadowColor: "#AA9CFF9C"
                shadowBlur: 0.54
                blurMax: 12
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            ShapePath {
                fillColor: "transparent"
                strokeColor: "#9CFF9C"
                strokeWidth: 1.4
                PathPolyline {
                    path: {
                        const w = trace.width, h = trace.height;
                        const v = root.levels;
                        const n = Math.min(8, v.length);
                        let sum = 0;
                        for (let k = 0; k < n; k++)
                            sum += v[k];
                        const pts = [];
                        const steps = 120;
                        for (let i = 0; i <= steps; i++) {
                            const t = i / steps;
                            let y = 0;
                            for (let k = 0; k < n; k++)
                                y += v[k] * Math.sin(2 * Math.PI * (k + 1) * 1.5 * t + root.phase * (k + 1) * 0.3);
                            const norm = Math.max(1, sum);
                            pts.push(Qt.point(w * t, h / 2 - (h / 2) * 0.9 * y / norm));
                        }
                        return pts;
                    }
                }
            }
        }
    }
}
