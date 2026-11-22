import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// CPU, GPU, memory, iGPU by shape: tiny = CPU alone; narrow and the
// line-drawn themes (classic, facade) = rows (label, figure, gauge) as many
// as fit; ring themes (constellation orbits, matrix dots, modulaire knobs)
// = the best grid of rings in wide / box / tall; strip = side by side.
// Gauges and rings take the theme's look.
ModuleBase {
    id: root

    Component.onCompleted: SystemStats.refCount++
    Component.onDestruction: SystemStats.refCount--

    readonly property var gpu: SystemStats.gpus.find(g => !g.integrated) ?? SystemStats.gpus[0] ?? null
    readonly property var igpu: SystemStats.gpus.length > 1 ? SystemStats.gpus.find(g => g.integrated) ?? null : null
    readonly property var stats: [
        { label: "CPU", value: SystemStats.cpu, detail: SystemStats.cpuTemp ? `${Math.round(SystemStats.cpuTemp)}°` : "" },
        ...(gpu ? [{ label: "GPU", value: gpu.busy, detail: gpu.temp ? `${Math.round(gpu.temp)}°` : "" }] : []),
        { label: "RAM", value: SystemStats.memory, detail: I18n.tr("system.memory", { used: I18n.number(SystemStats.memoryUsedGiB, 1), total: Math.round(SystemStats.memoryTotalGiB) }) },
        ...(igpu ? [{ label: "iGPU", value: igpu.busy, detail: igpu.temp ? `${Math.round(igpu.temp)}°` : "" }] : [])
    ]
    readonly property bool ringLook: ["orbit", "dots", "knob"].includes(theme.style.ring ?? "arc")
    readonly property string layout: shape === "tiny" ? "tiny" : shape === "strip" ? "strip" : shape === "narrow" || !ringLook ? "rows" : "rings"
    readonly property real rowHeight: t4 * 1.4 + t2 * 1.5 + 12
    readonly property var grid: bestGrid(stats.length, theme.style.ring === "knob" ? 60 : 90)

    // tiny: CPU.
    Column {
        visible: root.layout === "tiny"
        anchors.centerIn: parent
        width: parent.width
        spacing: root.gap / 2

        ThemedText {
            label: true
            text: "CPU"
            font.pixelSize: root.t4
            color: root.theme.color.soft
        }

        Figure {
            text: I18n.percent(SystemStats.cpu)
            pixelSize: root.figure(0.4, 0.3)
            color: SystemStats.cpu > 0.9 ? root.theme.color.urgent : root.theme.color.ink
        }

        Gauge {
            width: parent.width
            value: SystemStats.cpu
        }
    }

    // rows: as many as fit, spread over the height.
    Column {
        id: rows

        readonly property int count: Math.min(root.stats.length, root.fit(root.rowHeight, 4))

        visible: root.layout === "rows"
        anchors.fill: parent
        spacing: (height - count * root.rowHeight) / Math.max(1, count - 1)

        Repeater {
            model: root.stats.slice(0, rows.count)

            Column {
                required property var modelData
                width: rows.width
                height: root.rowHeight
                spacing: 4

                Item {
                    width: parent.width
                    height: rowFigure.height

                    ThemedText {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        label: true
                        text: modelData.label
                        font.pixelSize: root.t4 * 1.2
                        color: root.theme.color.soft
                    }

                    Figure {
                        id: rowFigure
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.percent(modelData.value)
                        pixelSize: root.t2 * 1.4
                        color: modelData.value > 0.9 ? root.theme.color.urgent : root.theme.color.ink
                    }

                    ThemedText {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 4
                        text: modelData.detail
                        font.pixelSize: root.t4 * 1.2
                        color: root.theme.color.soft
                    }
                }

                Gauge {
                    width: parent.width
                    value: modelData.value
                }
            }
        }
    }

    // rings: the best grid.
    Grid {
        visible: root.layout === "rings"
        anchors.centerIn: parent
        columns: root.grid.columns
        spacing: root.gap

        Repeater {
            model: root.layout === "rings" ? root.stats.slice(0, root.grid.n) : []

            Item {
                required property var modelData
                width: root.grid.size
                height: root.grid.size

                Ring {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * (root.theme.style.ring === "knob" ? 0.7 : 1)
                    height: width
                    value: modelData.value

                    Column {
                        visible: root.theme.style.ring !== "knob"
                        anchors.centerIn: parent

                        Figure {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.percent(modelData.value)
                            pixelSize: root.grid.size * 0.16
                        }

                        ThemedText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            label: true
                            text: modelData.label
                            font.pixelSize: root.t4
                            color: root.theme.color.soft
                        }
                    }
                }

                // Knob: value and label under it, on a small LCD.
                Display {
                    visible: root.theme.style.ring === "knob"
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.86
                    height: parent.height * 0.26
                    tint: "green"

                    ThemedText {
                        anchors.centerIn: parent
                        text: `${modelData.label} ${I18n.percent(modelData.value)}`
                        font.family: root.theme.font.lcd ?? root.theme.font.mono
                        font.pixelSize: Math.min(root.t3, parent.height * 0.6)
                        color: parent.ink
                    }
                }
            }
        }
    }

    // strip: side by side.
    Row {
        visible: root.layout === "strip"
        anchors.fill: parent
        spacing: root.gap * 1.5

        Repeater {
            model: root.layout === "strip" ? root.stats : []

            Column {
                required property var modelData
                width: (parent.width - parent.spacing * (root.stats.length - 1)) / root.stats.length
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Row {
                    spacing: root.gap / 2

                    ThemedText {
                        anchors.bottom: stripFigure.bottom
                        label: true
                        text: modelData.label
                        font.pixelSize: root.t4 * 1.2
                        color: root.theme.color.soft
                    }

                    Figure {
                        id: stripFigure
                        text: I18n.percent(modelData.value)
                        pixelSize: Math.min(root.ch * 0.42, root.t2 * 1.6)
                        color: modelData.value > 0.9 ? root.theme.color.urgent : root.theme.color.ink
                    }
                }

                Gauge {
                    width: parent.width
                    value: modelData.value
                }
            }
        }
    }
}
