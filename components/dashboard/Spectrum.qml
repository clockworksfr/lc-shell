import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.services
import qs.theme

// Live audio spectrum (Spectrum service, cava) in the theme's language:
// classic rounded bars; constellation thin glowing lines; facade
// segmented columns (unlit = ghost); modulaire oscilloscope trace on its
// green LCD; matrix columns of dots. `count` bands (resampled).
Item {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"
    property int count: 24
    property color color: theme.color.signal ?? theme.color.accent

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

                // facade / matrix: stacked cells or dots.
                Column {
                    visible: root.look === "facade" || root.look === "matrix"
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.look === "matrix" ? 3 : 2

                    Repeater {
                        id: cells
                        model: Math.max(4, Math.floor(band.height / (root.look === "matrix" ? 8 : 7)))

                        Rectangle {
                            required property int index
                            readonly property bool lit: (cells.count - index) / cells.count <= band.level + 0.001 && band.level > 0.02
                            width: root.look === "matrix" ? Math.min(5, band.width) : band.width
                            height: root.look === "matrix" ? width : 5
                            radius: root.look === "matrix" ? width / 2 : 1
                            color: lit ? root.color : (root.look === "facade" ? root.theme.color.ghost : Qt.alpha(root.theme.color.ink, 0.1))
                        }
                    }
                }
            }
        }
    }

    // modulaire: an oscilloscope trace on the green LCD.
    Rectangle {
        visible: root.look === "modulaire"
        anchors.fill: parent
        radius: 4
        color: root.theme.color.lcd ?? "#C6F37A"
        border.width: 2
        border.color: Qt.alpha("black", 0.6)

        Shape {
            anchors.fill: parent
            anchors.margins: 6
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: "transparent"
                strokeColor: root.theme.color.lcdInk ?? "#1A2410"
                strokeWidth: 2
                PathPolyline {
                    path: {
                        const w = root.width - 12, h = root.height - 12;
                        const pts = [];
                        const n = root.levels.length;
                        for (let i = 0; i < n; i++) {
                            const sign = i % 2 === 0 ? -1 : 1;
                            pts.push(Qt.point(w * i / Math.max(1, n - 1), h / 2 + sign * (h / 2) * root.levels[i] * 0.9));
                        }
                        return pts;
                    }
                }
            }
        }
    }
}
