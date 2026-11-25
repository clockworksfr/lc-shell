import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// CPU, GPU, memory, iGPU, by theme:
//   classic        rows: label, gauge, value aligned right (+ temperature)
//   facade         the same rows inside the VFD (cell bargraphs, amber
//                  above 85 %, 7-segment values)
//   constellation  one system of concentric orbits (CPU, GPU, RAM), the
//                  values listed beside it
//   modulaire      LED ladders (one per core, then GPU, RAM, T°) over a
//                  green LCD with the temperatures
//   matrix         rings of dots (red beyond 90 %)
// tiny: CPU alone; strip: side by side. Big cells (tiers large / poster):
// the gauges on top, the last minute's curves (CPU, GPU; poster: RAM)
// with average and peak, the probes at the bottom; poster: memory, GPU
// and the 5 busiest processes in a column on the right.
ModuleBase {
    id: root

    Component.onCompleted: SystemStats.refCount++
    Component.onDestruction: SystemStats.refCount--

    readonly property string look: theme.style.module ?? "classic"
    readonly property var gpu: SystemStats.gpus.find(g => !g.integrated) ?? SystemStats.gpus[0] ?? null
    readonly property var igpu: SystemStats.gpus.length > 1 ? SystemStats.gpus.find(g => g.integrated) ?? null : null
    readonly property var stats: [
        { label: "CPU", value: SystemStats.cpu, detail: SystemStats.cpuTemp ? `${Math.round(SystemStats.cpuTemp)}°` : "", color: "#9FB8FF" },
        ...(gpu ? [{ label: "GPU", value: gpu.busy, detail: gpu.temp ? `${Math.round(gpu.temp)}°` : "", color: "#F2A7D8" }] : []),
        { label: "RAM", value: SystemStats.memory, detail: I18n.tr("system.memory", { used: I18n.number(SystemStats.memoryUsedGiB, 1), total: Math.round(SystemStats.memoryTotalGiB) }), color: "#7EE0B5" },
        ...(igpu ? [{ label: "iGPU", value: igpu.busy, detail: igpu.temp ? `${Math.round(igpu.temp)}°` : "", color: "#E6E9F5" }] : [])
    ]
    readonly property bool ringLook: look === "modulaire" || look === "matrix"
    readonly property string layout: shape === "tiny" ? "tiny"
        : look === "modulaire" && (shape !== "strip" || ch >= 150) ? "ladders"
        : shape === "strip" && !(ringLook && ch >= 150) ? "strip"
        : look === "constellation" && shape !== "narrow" ? "orbits"
        : (look === "modulaire" || look === "matrix") && shape !== "narrow" ? "rings"
        : "rows"
    // Temperature probes (those the machine has), a row of small gauges.
    readonly property var temps: [
        { label: "CPU", value: SystemStats.cpuTemp },
        ...(gpu ? [{ label: "GPU", value: gpu.temp }] : []),
        ...(igpu ? [{ label: "iGPU", value: igpu.temp }] : []),
        { label: "SSD", value: SystemStats.diskTemp },
        { label: "RAM", value: SystemStats.ramTemp }
    ].filter(t => t.value > 0)
    readonly property bool showTemps: temps.length > 0 && shape !== "tiny" && layout !== "strip" && layout !== "ladders" && ch >= 230
    readonly property real tempsHeight: showTemps ? t3 * 2.6 : 0
    // Big cells: the gauges' band and the poster's right column.
    readonly property real sideWidth: poster ? Math.round(cw * 0.3) : 0
    readonly property real gaugesHeight: large ? Math.round((ch - tempsHeight - gap) * (poster ? 0.38 : 0.42)) : 0
    readonly property real gaugesBottom: large ? ch - gaugesHeight : showTemps ? tempsHeight + gap : 0
    readonly property real gaugesRight: poster ? sideWidth + gap : 0

    component TempsRow: Row {
        id: tempsRow

        property var m
        // As many probes as fit at 90 px each.
        readonly property var shown: tempsRow.m.temps.slice(0, Math.max(1, Math.floor((width + spacing) / (90 + spacing))))

        spacing: tempsRow.m.gap

        Repeater {
            model: tempsRow.shown

            Column {
                required property var modelData
                width: (tempsRow.width - (tempsRow.shown.length - 1) * tempsRow.spacing) / tempsRow.shown.length
                spacing: 4

                Item {
                    width: parent.width
                    height: tempValue.implicitHeight

                    ThemedText {
                        anchors.baseline: tempValue.baseline
                        label: true
                        text: parent.parent.modelData.label
                        font.pixelSize: tempsRow.m.t4
                        color: tempsRow.m.theme.color.soft
                    }

                    ThemedText {
                        id: tempValue
                        anchors.right: parent.right
                        text: `${Math.round(parent.parent.modelData.value)}°`
                        font.pixelSize: tempsRow.m.t3
                        font.features: ({ "tnum": 1 })
                        color: parent.parent.modelData.value >= 85 ? (tempsRow.m.theme.color.signal ?? tempsRow.m.theme.color.urgent) : tempsRow.m.theme.color.ink
                    }
                }

                // 20 → 100 °C.
                Gauge {
                    width: parent.width
                    value: (parent.modelData.value - 20) / 80
                    alarm: 0.8
                }
            }
        }
    }

    readonly property var grid: bestGrid(stats.length, look === "modulaire" ? 70 : 90)

    // tiny, dot / orbit themes: CPU in its ring, value and label inside.
    Ring {
        visible: root.layout === "tiny" && (root.look === "matrix" || root.look === "constellation")
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        value: SystemStats.cpu
        color: root.theme.color.ink

        Column {
            anchors.centerIn: parent

            Figure {
                anchors.horizontalCenter: parent.horizontalCenter
                text: `${Math.round(SystemStats.cpu * 100)}`
                glow: false
                pixelSize: Math.min(root.cw, root.ch) * 0.26
                color: SystemStats.cpu > 0.9 ? (root.theme.color.signal ?? root.theme.color.urgent) : root.theme.color.ink
            }

            ThemedText {
                anchors.horizontalCenter: parent.horizontalCenter
                label: true
                text: "CPU %"
                font.pixelSize: root.t4
                color: root.theme.color.soft
            }
        }
    }

    // tiny: CPU.
    ColumnLayout {
        visible: root.layout === "tiny" && root.look !== "matrix" && root.look !== "constellation"
        anchors.fill: parent
        spacing: root.gap / 2

        ThemedText {
            label: true
            text: "CPU"
            font.pixelSize: root.t4
            color: root.theme.color.soft
        }

        Figure {
            Layout.fillHeight: true
            // In the theme's screen where it has one (modulaire's LCD).
            inDisplay: true
            text: I18n.percent(SystemStats.cpu)
            pixelSize: root.figure(0.4, 0.3)
            color: SystemStats.cpu > 0.9 ? root.theme.color.urgent : root.theme.color.nixie ?? root.theme.color.ink
        }

        Gauge {
            Layout.fillWidth: true
            value: SystemStats.cpu
        }
    }

    // rows (classic, facade inside its VFD, narrow cells).
    Display {
        id: rowsDisplay

        visible: root.layout === "rows"
        // Only the VFD holds the rows (modulaire's LCD is for figures).
        screen: root.look === "facade"
        anchors.fill: parent
        anchors.bottomMargin: root.gaugesBottom
        anchors.rightMargin: root.gaugesRight

        ColumnLayout {
            id: rows

            readonly property real rowHeight: Math.max(root.t3 * 2.2, 30)
            readonly property int count: Math.min(root.stats.length, Math.max(1, Math.floor((height + spacing) / (rowHeight + spacing))))

            anchors.fill: parent
            spacing: root.gap / 2

            Item {
                Layout.fillHeight: true
            }

            Repeater {
                model: root.stats.slice(0, rows.count)

                RowLayout {
                    id: line

                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: rows.rowHeight
                    spacing: root.gap / 1.5

                    ThemedText {
                        Layout.preferredWidth: root.t3 * 2.8
                        label: true
                        text: line.modelData.label
                        font.family: rowsDisplay.textFont
                        font.capitalization: rowsDisplay.caps
                        font.pixelSize: root.t4 * 1.2
                        color: root.theme.color.soft
                    }

                    Gauge {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        value: line.modelData.value
                        alarm: root.look === "facade" ? 0.85 : 0.9
                        color: root.look === "facade" && line.modelData.value > 0.85 ? "#FFB547" : line.modelData.value > 0.9 ? root.theme.color.urgent : root.theme.color.accent
                    }

                    Column {
                        Layout.preferredWidth: root.t3 * 4.2
                        Layout.alignment: Qt.AlignVCenter

                        Figure {
                            anchors.right: parent.right
                            text: I18n.percent(line.modelData.value)
                            glow: false
                            pixelSize: root.t3 * 1.3
                            color: line.modelData.value > 0.9 ? root.theme.color.urgent : root.theme.color.ink
                        }

                        ThemedText {
                            anchors.right: parent.right
                            visible: !!line.modelData.detail && rows.rowHeight > root.t3 * 2.4
                            text: line.modelData.detail
                            font.pixelSize: root.t4
                            color: root.theme.color.soft
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // orbits (constellation): CPU / GPU / RAM on concentric orbits.
    RowLayout {
        visible: root.layout === "orbits"
        anchors.fill: parent
        anchors.bottomMargin: root.gaugesBottom
        anchors.rightMargin: root.gaugesRight
        spacing: root.gap

        Item {
            id: orbits

            readonly property real size: Math.min(height, width)

            Layout.fillHeight: true
            Layout.preferredWidth: Math.min(height, root.cw * 0.55)

            Repeater {
                model: root.stats.slice(0, 3)

                Item {
                    id: orbit

                    required property var modelData
                    required property int index
                    readonly property real r: orbits.size * [0.18, 0.3, 0.42][index]
                    readonly property real cx: orbits.width / 2
                    readonly property real cy: orbits.height / 2

                    anchors.fill: parent

                    Shape {
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: Qt.alpha(root.theme.color.ink, 0.14)
                            strokeWidth: 1
                            PathAngleArc {
                                centerX: orbit.cx
                                centerY: orbit.cy
                                radiusX: orbit.r
                                radiusY: orbit.r
                                startAngle: 0
                                sweepAngle: 360
                            }
                        }

                        ShapePath {
                            fillColor: "transparent"
                            strokeColor: orbit.modelData.color
                            strokeWidth: 2
                            capStyle: ShapePath.RoundCap
                            PathAngleArc {
                                centerX: orbit.cx
                                centerY: orbit.cy
                                radiusX: orbit.r
                                radiusY: orbit.r
                                startAngle: -90
                                sweepAngle: 360 * Math.min(1, orbit.modelData.value)
                            }
                        }
                    }

                    // The planet.
                    Rectangle {
                        readonly property real angle: (-90 + 360 * Math.min(1, orbit.modelData.value)) * Math.PI / 180
                        width: Math.max(7, orbits.size * 0.052)
                        height: width
                        radius: width / 2
                        x: orbit.cx + Math.cos(angle) * orbit.r - width / 2
                        y: orbit.cy + Math.sin(angle) * orbit.r - height / 2
                        color: orbit.modelData.color

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 2.4
                            height: width
                            radius: width / 2
                            color: Qt.alpha(orbit.modelData.color, 0.2)
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: root.gap / 2

            Repeater {
                model: root.stats

                RowLayout {
                    required property var modelData
                    Layout.fillWidth: true

                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: parent.modelData.color
                    }

                    ThemedText {
                        Layout.fillWidth: true
                        label: true
                        text: parent.modelData.label
                        font.pixelSize: root.t4 * 1.2
                        color: root.theme.color.soft
                    }

                    ThemedText {
                        text: I18n.percent(parent.modelData.value)
                        font.family: root.theme.font.display
                        font.weight: Font.Light
                        font.pixelSize: root.t2 * 1.1
                    }
                }
            }
        }
    }

    // rings: modulaire knobs (one LCD under), matrix dot rings.
    ColumnLayout {
        visible: root.layout === "rings"
        anchors.fill: parent
        anchors.bottomMargin: root.gaugesBottom
        anchors.rightMargin: root.gaugesRight
        spacing: root.gap / 2

        // Even cells over the whole room, each ring centered in its own.
        Grid {
            id: ringGrid

            // Big cells: one row in the gauges' band.
            readonly property var g: root.large ? { n: root.stats.length, columns: root.stats.length, rows: 1 } : root.bestGrid(root.stats.length, root.look === "modulaire" ? 70 : 90)
            readonly property real cellW: width / g.columns
            readonly property real cellH: height / g.rows

            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: g.columns
            spacing: 0

            Repeater {
                model: root.stats.slice(0, parent.g.n)

                Item {
                    width: ringGrid.cellW
                    height: ringGrid.cellH

                    required property var modelData

                    Item {
                        id: knob

                        readonly property var modelData: parent.modelData
                        readonly property real size: Math.min(ringGrid.cellW, ringGrid.cellH, root.large ? root.heroMax * 1.3 : Infinity) - root.gap

                        anchors.centerIn: parent
                        width: size
                        height: size

                        Ring {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width * (root.look === "modulaire" ? 0.8 : 1)
                            height: width
                            value: knob.modelData.value
                            color: root.theme.color.ink

                            Column {
                                visible: root.look === "matrix"
                                anchors.centerIn: parent

                                Figure {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: I18n.percent(knob.modelData.value)
                                    glow: false
                                    pixelSize: knob.size * 0.16
                                }

                                ThemedText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    label: true
                                    text: knob.modelData.label
                                    font.pixelSize: root.t4
                                    color: root.theme.color.soft
                                }
                            }
                        }

                        // Silk label under the knob.
                        ThemedText {
                            visible: root.look === "modulaire"
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            label: true
                            text: knob.modelData.label
                            font.family: root.theme.font.mono
                            font.pixelSize: root.t4
                            color: root.theme.color.soft
                        }
                    }
                }
            }
        }

        // modulaire: one LCD with every value.
        Display {
            id: lcd

            visible: root.look === "modulaire"
            Layout.fillWidth: true
            Layout.preferredHeight: root.t3 * 2.4
            tint: "green"

            ThemedText {
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: root.stats.map(s => `${s.label} ${Math.round(s.value * 100)}`).join("  ")
                font.family: lcd.textFont
                font.capitalization: lcd.caps
                font.pixelSize: Math.min(root.t3, lcd.height * 0.5)
                color: lcd.ink
            }
        }
    }

    // ladders (modulaire): a ladder per core, then GPU,
    // RAM and the CPU's temperature (30–100 °C), one silk label row under
    // them, a two-line green LCD below (temperatures, network).
    Column {
        id: ladders

        visible: root.layout === "ladders"
        anchors.fill: parent
        anchors.bottomMargin: root.gaugesBottom
        anchors.rightMargin: root.gaugesRight
        spacing: 10

        readonly property real lcdHeight: Math.min(height * 0.36, root.t3 * 4.6)
        readonly property real labelHeight: Math.max(12, root.t4) * 1.4
        readonly property real ladderHeight: Math.max(40, height - lcdHeight - labelHeight - spacing * 2)
        readonly property var singles: [
            ...(root.gpu ? [{ label: "GPU", value: root.gpu.busy }] : []),
            { label: "RAM", value: SystemStats.memory },
            // The CPU's temperature, 30 to 100 °C.
            ...(SystemStats.cpuTemp > 0 ? [{ label: I18n.tr("system.cpuTempShort"), value: (SystemStats.cpuTemp - 30) / 70 }] : [])
        ]
        readonly property var cores: SystemStats.cores.length ? SystemStats.cores : [SystemStats.cpu]
        readonly property real gapX: width * 0.04
        readonly property real singleWidth: width * 0.07
        readonly property real coresWidth: width - singles.length * (singleWidth + gapX)

        Component.onCompleted: NetworkService.watchers++
        Component.onDestruction: NetworkService.watchers--

        Row {
            width: parent.width
            height: ladders.ladderHeight
            spacing: ladders.gapX

            Row {
                id: coreRow
                readonly property real column: Math.min(22, (ladders.coresWidth - (ladders.cores.length - 1) * 2) / ladders.cores.length)
                width: ladders.coresWidth
                height: parent.height
                // Columns spread over the width.
                spacing: Math.max(2, (width - ladders.cores.length * column) / Math.max(1, ladders.cores.length - 1))

                Repeater {
                    model: ladders.cores

                    LedLadder {
                        required property real modelData
                        width: coreRow.column
                        height: coreRow.height
                        count: 12
                        value: modelData
                    }
                }
            }

            Repeater {
                model: ladders.singles

                LedLadder {
                    required property var modelData
                    width: ladders.singleWidth
                    height: parent.height
                    count: 12
                    value: modelData.value
                }
            }
        }

        // Silk labels, each under its ladder(s).
        Row {
            width: parent.width
            height: ladders.labelHeight
            spacing: ladders.gapX

            Item {
                width: ladders.coresWidth
                height: parent.height

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("system.cores", { n: ladders.cores.length })
                    font.pixelSize: Math.max(12, root.t4)
                    color: root.theme.color.ink
                }
            }

            Repeater {
                model: ladders.singles

                Item {
                    required property var modelData
                    width: ladders.singleWidth
                    height: parent.height

                    ThemedText {
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        font.pixelSize: Math.max(12, root.t4)
                        color: root.theme.color.ink
                    }
                }
            }
        }

        Display {
            id: ladderLcd
            width: parent.width
            height: ladders.lcdHeight
            tint: "green"

            Column {
                anchors.verticalCenter: parent.verticalCenter
                x: 12
                width: parent.width - 24
                spacing: 2

                Repeater {
                    model: [
                        [
                            SystemStats.cpuTemp > 0 ? `CPU ${Math.round(SystemStats.cpuTemp)}°` : `CPU ${Math.round(SystemStats.cpu * 100)} %`,
                            root.gpu?.temp ? `GPU ${Math.round(root.gpu.temp)}°` : "",
                            I18n.tr("system.memory", { used: I18n.number(SystemStats.memoryUsedGiB, 1), total: Math.round(SystemStats.memoryTotalGiB) })
                        ].filter(t => !!t).join(" · "),
                        `NET ↓${I18n.bytes(NetworkService.rxRate, true)} ↑${I18n.bytes(NetworkService.txRate, true)}`
                    ]

                    ThemedText {
                        required property string modelData
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData
                        font.family: ladderLcd.textFont
                        font.capitalization: Font.AllUppercase
                        font.pixelSize: Math.min(root.t3, (ladderLcd.height - 20) / 2.9)
                        font.weight: Font.Black
                        color: ladderLcd.ink
                    }
                }
            }
        }
    }

    // strip: side by side.
    RowLayout {
        visible: root.layout === "strip"
        anchors.fill: parent
        spacing: root.gap * 1.5

        Repeater {
            model: root.layout === "strip" ? root.stats : []

            ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 4

                RowLayout {
                    spacing: root.gap / 2

                    ThemedText {
                        Layout.alignment: Qt.AlignBottom
                        label: true
                        text: parent.parent.modelData.label
                        font.pixelSize: root.t4 * 1.2
                        color: root.theme.color.soft
                    }

                    Figure {
                        inDisplay: true
                        glow: false
                        text: I18n.percent(parent.parent.modelData.value)
                        pixelSize: Math.min(root.ch * 0.42, root.t2 * 1.6)
                        color: parent.parent.modelData.value > 0.9 ? root.theme.color.urgent : root.theme.color.nixie ?? root.theme.color.ink
                    }
                }

                Gauge {
                    Layout.fillWidth: true
                    value: parent.modelData.value
                }
            }
        }
    }

    // Facade: the temperatures in a VFD too (under the gauges' one).
    Display {
        visible: root.showTemps && root.look === "facade"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -6
        height: root.tempsHeight + 12
    }

    // Temperatures under the gauges.
    TempsRow {
        visible: root.showTemps
        m: root
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: root.gaugesRight
        anchors.bottom: parent.bottom
        height: root.tempsHeight
    }

    // --- Big cells ---

    function average(values: var): real {
        return values.length ? values.reduce((a, b) => a + b, 0) / values.length : 0;
    }

    // The last minute, in the theme's language: matrix columns of dots,
    // facade VFD segments, area and line elsewhere.
    component HistoryChart: Canvas {
        id: hc

        property var m
        property var values: []
        property color ink: m.theme.color.accent
        readonly property string look: m.look
        onValuesChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onInkChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const v = hc.values;
            const n = 30;
            if (look === "matrix" || look === "facade") {
                const rows = look === "matrix" ? 10 : 12;
                const cw = width / n, rh = height / rows;
                for (let i = 0; i < n; i++) {
                    const value = v[v.length - n + i] ?? 0;
                    const lit = Math.round(value * rows);
                    for (let r = 0; r < rows; r++) {
                        const on = r < lit;
                        ctx.fillStyle = on ? hc.ink : Qt.alpha(hc.ink, 0.1);
                        if (look === "matrix") {
                            ctx.beginPath();
                            ctx.arc(i * cw + cw / 2, height - r * rh - rh / 2, Math.min(cw, rh) * 0.3, 0, Math.PI * 2);
                            ctx.fill();
                        } else {
                            ctx.fillRect(i * cw + 1, height - (r + 1) * rh + 1, cw - 2, rh - 2);
                        }
                    }
                }
                return;
            }
            // Grid lines.
            ctx.strokeStyle = Qt.alpha(hc.ink, 0.15);
            ctx.lineWidth = 1;
            for (const f of [0.25, 0.5, 0.75]) {
                ctx.beginPath();
                ctx.moveTo(0, height * f);
                ctx.lineTo(width, height * f);
                ctx.stroke();
            }
            if (v.length < 2)
                return;
            const pts = v.map((value, i) => [width * (n - v.length + i) / (n - 1), height - value * (height - 3)]);
            ctx.beginPath();
            ctx.moveTo(pts[0][0], height);
            for (const [x, y] of pts)
                ctx.lineTo(x, y);
            ctx.lineTo(pts[pts.length - 1][0], height);
            ctx.closePath();
            ctx.fillStyle = Qt.alpha(hc.ink, look === "modulaire" ? 0.12 : 0.18);
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(pts[0][0], pts[0][1]);
            for (const [x, y] of pts.slice(1))
                ctx.lineTo(x, y);
            ctx.strokeStyle = hc.ink;
            ctx.lineWidth = 2.5;
            ctx.stroke();
        }
    }

    // A curve with its figure, average and peak.
    component HistoryZone: ModuleZone {
        id: hzone

        property var m
        property string name
        property real value
        property var values: []
        property real temp: 0

        label: hzone.name
        labelSize: hzone.m.t4
        gap: hzone.m.gap
        tint: "green"

        readonly property color tone: hzone.onDisplay ? hzone.ink : hzone.value > 0.9 ? hzone.m.theme.color.urgent : (hzone.m.theme.color.signal ?? hzone.m.theme.color.accent)

        Row {
            id: hzHead
            width: parent.width
            spacing: hzone.m.gap

            ThemedText {
                id: hzFigure
                text: I18n.percent(hzone.value)
                font.family: hzone.onDisplay ? hzone.textFont : (hzone.m.theme.font.display ?? hzone.m.theme.font.family)
                font.pixelSize: hzone.m.t2
                font.features: ({ "tnum": 1 })
                color: hzone.onDisplay ? hzone.ink : hzone.m.theme.color.ink
            }

            ThemedText {
                anchors.baseline: hzFigure.baseline
                text: I18n.tr("system.avgPeak", { avg: I18n.percent(hzone.m.average(hzone.values)), peak: I18n.percent(Math.max(0, ...hzone.values)) }) + (hzone.temp > 0 ? ` · ${Math.round(hzone.temp)}°` : "")
                font.family: hzone.textFont
                font.pixelSize: hzone.m.t4 * 1.1
                font.features: ({ "tnum": 1 })
                color: hzone.soft
            }
        }

        HistoryChart {
            m: hzone.m
            y: hzHead.height + hzone.m.gap * 0.6
            width: parent.width
            height: parent.height - y
            values: hzone.values
            ink: hzone.tone
        }
    }

    Row {
        id: curves

        visible: root.large
        y: root.gaugesHeight + root.gap
        width: root.cw - root.gaugesRight
        height: root.ch - y - (root.showTemps ? root.tempsHeight + root.gap : 0)
        spacing: root.gap

        readonly property var series: [
            { name: "CPU", value: SystemStats.cpu, values: SystemStats.cpuHistory, temp: SystemStats.cpuTemp },
            ...(root.gpu ? [{ name: "GPU", value: root.gpu.busy, values: SystemStats.gpuHistory, temp: root.gpu.temp }] : []),
            ...(root.poster ? [{ name: "RAM", value: SystemStats.memory, values: SystemStats.memoryHistory, temp: 0 }] : [])
        ]

        Repeater {
            model: root.large ? curves.series : []

            HistoryZone {
                required property var modelData
                m: root
                width: (curves.width - (curves.series.length - 1) * curves.spacing) / curves.series.length
                height: curves.height
                name: modelData.name
                value: modelData.value
                values: modelData.values
                temp: modelData.temp
            }
        }
    }

    // Poster: memory, GPU and the busiest processes on the right.
    property var processes: []
    Timer {
        interval: 3000
        repeat: true
        running: root.poster && root.visible
        triggeredOnStart: true
        onTriggered: if (!top.running) top.running = true
    }
    Process {
        id: top
        command: ["ps", "-eo", "comm=,pcpu=", "--sort=-pcpu"]
        stdout: StdioCollector {
            onStreamFinished: root.processes = text.trim().split("\n").filter(l => !/^ps\s/.test(l.trim())).slice(0, 5).map(l => {
                const m = /^(.*\S)\s+([\d.]+)$/.exec(l.trim());
                return m ? { name: m[1], cpu: parseFloat(m[2]) } : null;
            }).filter(p => !!p)
        }
    }

    Column {
        visible: root.poster
        x: root.cw - root.sideWidth
        width: root.sideWidth
        height: root.ch
        spacing: root.gap

        ModuleZone {
            id: memZone
            width: parent.width
            height: Math.round((parent.height - 2 * parent.spacing) * 0.26)
            label: I18n.tr("system.zone.memory")
            labelSize: root.t4
            gap: root.gap
            tint: "green"

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: root.gap * 0.5

                ThemedText {
                    text: I18n.tr("system.memory", { used: I18n.number(SystemStats.memoryUsedGiB, 1), total: Math.round(SystemStats.memoryTotalGiB) })
                    font.family: memZone.onDisplay ? memZone.textFont : (root.theme.font.display ?? root.theme.font.family)
                    font.pixelSize: root.t2 * 0.8
                    font.features: ({ "tnum": 1 })
                    color: memZone.ink
                }

                Rectangle {
                    width: parent.width
                    height: Math.max(8, root.t4 * 0.6)
                    radius: height / 2
                    color: Qt.alpha(memZone.ink, 0.15)

                    Rectangle {
                        width: parent.width * SystemStats.memory
                        height: parent.height
                        radius: parent.radius
                        color: memZone.onDisplay ? memZone.ink : (root.theme.color.signal ?? root.theme.color.accent)
                    }
                }
            }
        }

        ModuleZone {
            id: gpuZone
            visible: !!root.gpu
            width: parent.width
            height: Math.round((parent.height - 2 * parent.spacing) * 0.26)
            label: "GPU"
            labelSize: root.t4
            gap: root.gap
            tint: "green"

            Grid {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                columns: 2
                columnSpacing: root.gap

                Repeater {
                    model: [
                        { label: I18n.tr("system.load"), value: I18n.percent(root.gpu?.busy ?? 0) },
                        { label: I18n.tr("system.temp"), value: root.gpu?.temp ? `${Math.round(root.gpu.temp)}°` : "–" }
                    ]

                    Column {
                        required property var modelData
                        width: (gpuZone.body.width - root.gap) / 2

                        ThemedText {
                            label: true
                            text: gpuZone.onDisplay ? modelData.label.toUpperCase() : modelData.label
                            font.family: gpuZone.textFont
                            font.pixelSize: root.t4
                            color: gpuZone.soft
                        }

                        ThemedText {
                            text: modelData.value
                            font.family: gpuZone.onDisplay ? gpuZone.textFont : (root.theme.font.display ?? root.theme.font.family)
                            font.pixelSize: root.t2 * 0.8
                            font.features: ({ "tnum": 1 })
                            color: gpuZone.ink
                        }
                    }
                }
            }
        }

        ModuleZone {
            id: procZone
            width: parent.width
            height: parent.height - memZone.height - (gpuZone.visible ? gpuZone.height + parent.spacing : 0) - parent.spacing
            label: I18n.tr("system.zone.processes")
            labelSize: root.t4
            gap: root.gap
            tint: "green"

            Column {
                width: parent.width
                spacing: root.gap * 0.4

                Repeater {
                    model: root.processes

                    Item {
                        required property var modelData
                        width: procZone.body.width
                        height: root.t3 * 1.6

                        ThemedText {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - procCpu.width - root.gap
                            elide: Text.ElideRight
                            text: modelData.name
                            font.family: procZone.onDisplay ? procZone.textFont : root.theme.font.mono
                            font.pixelSize: root.t3
                            color: procZone.ink
                        }

                        ThemedText {
                            id: procCpu
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.tr("format.percent", { value: I18n.number(modelData.cpu, 0) })
                            font.family: procZone.textFont
                            font.pixelSize: root.t3
                            font.features: ({ "tnum": 1 })
                            color: procZone.soft
                        }
                    }
                }
            }
        }
    }
}
