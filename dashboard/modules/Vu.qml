import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// VU meter of the default output (design study 8, § 5): left / right
// peaks in dB (−48..+3) after the output volume, peaks held 1.2 s then
// falling 12 dB/s, values ("−6") and a dB scale when there is room, in
// each theme's language:
//   classic        segment rows (green, yellow from −9, red from −3)
//   constellation  comets
//   facade         cream dials with damped needles (+ VFD spectrum)
//   modulaire      oscilloscope CRT + LED ladders
//   matrix         a ring of dot rays (box / tall / tiny), dot rows else
// Options: preVolume (true: the raw signal, before the output volume).
ModuleBase {
    id: root

    readonly property string look: theme.style.module ?? "classic"
    readonly property real gain: options.preVolume ? 1 : Audio.muted ? 0 : Math.pow(Audio.volume, 3)

    // dB levels (attack fast, release ~24 dB/s) and held peaks.
    property real levelL: -48
    property real levelR: -48
    property real holdL: -48
    property real holdR: -48
    property real holdAtL: 0
    property real holdAtR: 0
    property real lastPeakAt: 0

    function toDb(peak: real): real {
        const p = peak * gain;
        return p <= 0 ? -48 : Math.max(-48, Math.min(3, 20 * Math.log10(p)));
    }

    // 0..1 position of a dB value on the −48..+3 scale.
    function frac(db: real): real {
        return Math.max(0, Math.min(1, (db + 48) / 51));
    }

    function label(db: real): string {
        return db <= -47.5 ? "−∞" : `${db < 0 ? "−" : db > 0 ? "+" : ""}${Math.abs(Math.round(db))}`;
    }

    PwNodePeakMonitor {
        id: monitor
        node: Audio.sink
        enabled: root.visible
        onPeaksChanged: root.lastPeakAt = Date.now()
    }

    Timer {
        interval: 50
        repeat: true
        running: root.visible
        onTriggered: {
            const now = Date.now();
            // PipeWire stops sending peaks in silence: old ones are silence.
            const silent = now - root.lastPeakAt > 250;
            const peaks = monitor.peaks;
            const tl = silent ? -48 : root.toDb(peaks[0] ?? 0);
            const tr = silent ? -48 : root.toDb(peaks[1] ?? peaks[0] ?? 0);
            root.levelL = tl > root.levelL ? tl : Math.max(tl, root.levelL - 1.2);
            root.levelR = tr > root.levelR ? tr : Math.max(tr, root.levelR - 1.2);
            if (root.levelL >= root.holdL) {
                root.holdL = root.levelL;
                root.holdAtL = now;
            } else if (now - root.holdAtL > 1200) {
                root.holdL = Math.max(root.levelL, root.holdL - 0.6);
            }
            if (root.levelR >= root.holdR) {
                root.holdR = root.levelR;
                root.holdAtR = now;
            } else if (now - root.holdAtR > 1200) {
                root.holdR = Math.max(root.levelR, root.holdR - 0.6);
            }
        }
    }

    readonly property bool roomy: ch > 220 && shape !== "strip"
    readonly property var channels: [
        { name: I18n.tr("vu.left"), db: levelL, hold: holdL },
        { name: I18n.tr("vu.right"), db: levelR, hold: holdR }
    ]

    // --- classic / constellation / matrix rows -------------------------

    // One channel: name, bar (segments, comet or dots), value.
    component LevelRow: Item {
        id: row

        property var m
        property var ch_
        // dB figures under the bar (last row, when there is room).
        property bool withScale: false
        readonly property string look: m.look
        readonly property real rowHeight: Math.max(m.t3 * 1.6, 18)

        implicitHeight: rowHeight + (withScale ? m.t4 * 1.6 : 0)

        ThemedText {
            id: name
            y: (row.rowHeight - height) / 2
            width: row.m.t3 * 1.4
            label: true
            text: row.ch_.name
            font.pixelSize: row.m.t4
            color: row.m.theme.color.soft
        }

        ThemedText {
            id: value
            anchors.right: parent.right
            y: (row.rowHeight - height) / 2
            width: row.m.t3 * 2.6
            horizontalAlignment: Text.AlignRight
            text: row.m.label(row.ch_.db)
            font.family: row.m.theme.font.mono
            font.pixelSize: row.m.t3
            font.features: ({ "tnum": 1 })
            color: row.ch_.db > -3 ? (row.m.theme.color.signal ?? row.m.theme.color.urgent) : row.m.theme.color.ink
        }

        Item {
            id: bar

            anchors.left: name.right
            anchors.right: value.left
            anchors.rightMargin: row.m.gap / 2
            y: (row.rowHeight - height) / 2
            height: row.look === "constellation" ? 10 : Math.max(8, row.rowHeight * 0.6)

            // classic: segments.
            Row {
                visible: row.look === "classic" || row.look === "facade" || row.look === "modulaire"
                anchors.fill: parent
                spacing: 3

                Repeater {
                    id: segs
                    model: Math.max(8, Math.floor(bar.width / 22))

                    Rectangle {
                        required property int index
                        readonly property real at: (index + 0.5) / segs.count
                        readonly property real atDb: at * 51 - 48
                        readonly property bool lit: at <= row.m.frac(row.ch_.db)
                        readonly property bool isHold: Math.abs(at - row.m.frac(row.ch_.hold)) < 0.5 / segs.count && row.ch_.hold > -47
                        width: (bar.width - 3 * (segs.count - 1)) / segs.count
                        height: bar.height
                        radius: 2
                        color: isHold ? row.m.theme.color.ink : !lit ? row.m.theme.color.surface3 : atDb > -3 ? row.m.theme.color.urgent : atDb > -9 ? row.m.theme.color.warn : row.m.theme.color.accent
                    }
                }
            }

            // constellation: a comet.
            Item {
                visible: row.look === "constellation"
                anchors.fill: parent

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 2
                    color: "#2A3350"
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * row.m.frac(row.ch_.db)
                    height: 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: "transparent"
                        }
                        GradientStop {
                            position: 1
                            color: "#9FB8FF"
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * row.m.frac(row.ch_.db) - width / 2
                    width: 8
                    height: 8
                    radius: 4
                    color: "#FFFFFF"

                    Rectangle {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        radius: 9
                        color: Qt.alpha("#9FB8FF", 0.3)
                    }
                }

                // Held peak.
                Rectangle {
                    visible: row.ch_.hold > -47
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width * row.m.frac(row.ch_.hold) - width / 2
                    width: 5
                    height: 5
                    radius: 2.5
                    color: "#F2A7D8"
                }
            }

            // matrix: dots.
            Row {
                visible: row.look === "matrix"
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    id: dots
                    model: Math.max(8, Math.floor(bar.width / 10))

                    Rectangle {
                        required property int index
                        readonly property real at: (index + 0.5) / dots.count
                        readonly property bool lit: at <= row.m.frac(row.ch_.db)
                        width: 6
                        height: 6
                        radius: 3
                        color: lit ? (at * 51 - 48 > -3 ? (row.m.theme.color.signal ?? "#E5323A") : row.m.theme.color.ink) : Qt.alpha(row.m.theme.color.ink, 0.12)
                    }
                }
            }
        }

        Repeater {
            // Fewer marks on a short bar (−3 and 0 read as "−30" there).
            model: !row.withScale ? [] : bar.width < 260 ? [-40, -20, 0] : bar.width < 420 ? [-40, -20, -10, 0] : [-40, -30, -20, -10, -3, 0]

            ThemedText {
                required property int modelData
                x: bar.x + bar.width * row.m.frac(modelData) - width / 2
                y: row.rowHeight + 2
                text: modelData === 0 ? "0" : `−${Math.abs(modelData)}`
                font.family: row.m.theme.font.mono
                font.pixelSize: row.m.t4
                color: modelData >= -3 ? (row.m.theme.color.signal ?? row.m.theme.color.urgent) : row.m.theme.color.soft
            }
        }
    }

    // Rows: classic / constellation (all shapes), matrix (wide / strip /
    // narrow). Box / tall add the spectrum above.
    ColumnLayout {
        visible: root.look === "classic" || root.look === "constellation" || (root.look === "matrix" && (root.shape === "wide" || root.shape === "strip" || root.shape === "narrow"))
        anchors.fill: parent
        spacing: root.gap / 2

        AudioSpectrum {
            visible: root.shape === "box" || root.shape === "tall" || (root.look === "matrix" && root.shape === "wide")
            Layout.fillWidth: true
            Layout.fillHeight: true
            count: Math.max(12, Math.min(32, Math.floor(width / 18)))
        }

        Item {
            visible: !(root.shape === "box" || root.shape === "tall" || (root.look === "matrix" && root.shape === "wide"))
            Layout.fillHeight: true
        }

        // A fixed model (2 channels): the rows read their level; a model
        // rebuilt at each update recreated every row and its dots 20 times a
        // second.
        Repeater {
            model: 2

            LevelRow {
                required property int index
                m: root
                ch_: root.channels[index]
                withScale: root.roomy && index === 1
                Layout.fillWidth: true
            }
        }

        Item {
            visible: !(root.shape === "box" || root.shape === "tall" || (root.look === "matrix" && root.shape === "wide"))
            Layout.fillHeight: true
        }
    }

    // --- facade: cream dials (+ VFD spectrum) --------------------------

    GridLayout {
        visible: root.look === "facade"
        anchors.fill: parent
        // Wide / strip: dials then the VFD; box: dials over the VFD;
        // tall / narrow / tiny: stacked.
        columns: root.shape === "wide" || root.shape === "strip" ? 3 : root.shape === "box" ? 2 : 1
        columnSpacing: root.gap
        rowSpacing: root.gap

        VuDial {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: Math.max(140, root.cw * (root.shape === "wide" || root.shape === "strip" ? 0.3 : 1))
            // A dial face keeps its proportions (about 1.5 : 1).
            Layout.maximumHeight: width / 1.4
            Layout.alignment: Qt.AlignCenter
            db: root.levelL
            channel: I18n.tr("vu.left")
        }

        VuDial {
            visible: root.shape !== "tiny"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumWidth: Math.max(140, root.cw * (root.shape === "wide" || root.shape === "strip" ? 0.3 : 1))
            Layout.maximumHeight: width / 1.4
            Layout.alignment: Qt.AlignCenter
            db: root.levelR
            channel: I18n.tr("vu.right")
        }

        Display {
            visible: root.shape !== "tiny" && root.shape !== "narrow"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.columnSpan: root.shape === "box" ? 2 : 1

            AudioSpectrum {
                anchors.fill: parent
                count: Math.max(12, Math.min(32, Math.floor(width / 14)))
            }
        }
    }

    // --- modulaire: CRT + LED ladders ----------------------------------

    GridLayout {
        visible: root.look === "modulaire"
        anchors.fill: parent
        columns: root.shape === "tall" ? 1 : 3
        columnSpacing: root.gap
        rowSpacing: root.gap

        AudioSpectrum {
            visible: root.shape !== "tiny" && root.shape !== "narrow"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.columnSpan: root.shape === "tall" ? 1 : 1
        }

        Repeater {
            model: 2

            ColumnLayout {
                id: ladder

                required property int index
                readonly property var modelData: root.channels[index]
                Layout.fillHeight: root.shape !== "tall"
                Layout.fillWidth: root.shape === "tall" || root.shape === "tiny" || root.shape === "narrow"
                Layout.preferredWidth: root.shape === "tall" ? -1 : Math.max(28, root.cw * 0.08)
                spacing: 4

                LedLadder {
                    vertical: root.shape !== "tall"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    value: root.frac(modelData.db)
                }

                ThemedText {
                    Layout.alignment: Qt.AlignHCenter
                    label: true
                    text: modelData.name
                    font.family: root.theme.font.mono
                    font.pixelSize: root.t4
                    color: root.theme.color.soft
                }
            }
        }
    }

    // --- matrix: ring of dot rays (box / tall / tiny) ------------------

    Item {
        visible: root.look === "matrix" && (root.shape === "box" || root.shape === "tall" || root.shape === "tiny")
        anchors.fill: parent

        Item {
            id: ring

            readonly property real size: Math.min(parent.width, parent.height)
            readonly property real r0: size * 0.28
            readonly property real step: size * 0.055

            anchors.centerIn: parent
            width: size
            height: size

            Component.onCompleted: Spectrum.refCount++
            Component.onDestruction: Spectrum.refCount--

            Repeater {
                model: 64

                Item {
                    id: ray

                    required property int index
                    readonly property real angle: index / 64 * Math.PI * 2 - Math.PI / 2
                    readonly property real level: {
                        const v = Spectrum.values;
                        if (!v.length)
                            return 0;
                        const k = index < 32 ? index : 63 - index;
                        return v[Math.min(v.length - 1, Math.floor(k * v.length / 32))] ?? 0;
                    }

                    Repeater {
                        model: 3

                        Rectangle {
                            required property int index
                            readonly property bool lit: (index + 1) / 3 <= ray.level + 0.15
                            readonly property real r: ring.r0 + index * ring.step
                            width: Math.max(3, ring.size * 0.02)
                            height: width
                            radius: width / 2
                            x: ring.size / 2 + Math.cos(ray.angle) * r - width / 2
                            y: ring.size / 2 + Math.sin(ray.angle) * r - height / 2
                            color: lit ? (index === 2 && Math.max(root.levelL, root.levelR) > -3 ? (root.theme.color.signal ?? root.theme.color.ink) : root.theme.color.ink) : Qt.alpha(root.theme.color.ink, 0.1)
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent

                HeroText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.label(Math.max(root.levelL, root.levelR))
                    pixelSize: ring.size * 0.16
                    color: Math.max(root.levelL, root.levelR) > -3 ? (root.theme.color.signal ?? root.theme.color.ink) : root.theme.color.ink
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    label: true
                    text: "dB"
                    font.pixelSize: root.t4
                    color: root.theme.color.soft
                }
            }
        }
    }
}
