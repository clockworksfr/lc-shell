import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// CPU, GPU, memory, iGPU (design study 8, § 4), by theme:
//   classic        rows: label, gauge, value aligned right (+ temperature)
//   facade         the same rows inside the VFD (cell bargraphs, amber
//                  above 85 %, 7-segment values)
//   constellation  one system of concentric orbits (CPU, GPU, RAM), the
//                  values listed beside it
//   modulaire      rotary knobs with their silk label, one LCD under them
//   matrix         rings of dots (red beyond 90 %)
// tiny: CPU alone; strip: side by side.
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
    readonly property string layout: shape === "tiny" ? "tiny" : shape === "strip" ? "strip"
        : look === "constellation" && shape !== "narrow" ? "orbits"
        : (look === "modulaire" || look === "matrix") && shape !== "narrow" ? "rings"
        : "rows"
    readonly property var grid: bestGrid(stats.length, look === "modulaire" ? 70 : 90)

    // tiny: CPU.
    ColumnLayout {
        visible: root.layout === "tiny"
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
        spacing: root.gap / 2

        Grid {
            readonly property var g: root.bestGrid(root.stats.length, root.look === "modulaire" ? 70 : 90)

            Layout.alignment: Qt.AlignHCenter
            Layout.fillHeight: true
            columns: g.columns
            spacing: root.gap

            Repeater {
                model: root.stats.slice(0, parent.g.n)

                Item {
                    id: knob

                    required property var modelData
                    readonly property real size: Math.min(parent.g.size, (root.ch - (root.look === "modulaire" ? root.t3 * 2.6 : 0)) / parent.g.rows - root.gap)

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
}
