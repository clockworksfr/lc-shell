import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// CPU, memory, GPU(s). S: side-by-side figures with a bar; M: 2 × 2
// tiles with temperatures; L: CPU and GPU curves over the last 2 minutes,
// then memory and the other GPU.
ModuleBase {
    id: root

    Component.onCompleted: SystemStats.refCount++
    Component.onDestruction: SystemStats.refCount--

    readonly property var gpu: SystemStats.gpus.find(g => !g.integrated) ?? SystemStats.gpus[0] ?? null
    readonly property var igpu: SystemStats.gpus.length > 1 ? SystemStats.gpus.find(g => g.integrated) ?? null : null
    readonly property var tiles: [
        { key: "cpu", label: "CPU", value: SystemStats.cpu, detail: SystemStats.cpuTemp ? `${Math.round(SystemStats.cpuTemp)}°` : "" },
        { key: "ram", label: "RAM", value: SystemStats.memory, detail: I18n.tr("system.memory", { used: I18n.number(SystemStats.memoryUsedGiB, 1), total: Math.round(SystemStats.memoryTotalGiB) }) },
        ...(gpu ? [{ key: "gpu", label: "GPU", value: gpu.busy, detail: gpu.temp ? `${Math.round(gpu.temp)}°` : "" }] : []),
        ...(igpu ? [{ key: "igpu", label: "iGPU", value: igpu.busy, detail: igpu.temp ? `${Math.round(igpu.temp)}°` : "" }] : [])
    ]
    readonly property var shown: tier === "S" ? tiles.slice(0, 3) : tiles.slice(0, 4)

    // Last 2 minutes (L curves).
    property var cpuHistory: []
    property var gpuHistory: []

    Timer {
        running: root.tier === "L"
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.cpuHistory = [...root.cpuHistory, SystemStats.cpu].slice(-60);
            root.gpuHistory = [...root.gpuHistory, root.gpu?.busy ?? 0].slice(-60);
        }
    }

    // S and M: tiles (S one row, M 2 × 2).
    Grid {
        id: tileGrid

        visible: root.tier !== "L"
        anchors.fill: parent
        // S: side by side, or stacked in a tall cell.
        columns: root.tier === "S" ? (root.inner.height > root.inner.width ? 1 : root.shown.length) : 2
        spacing: root.gap

        Repeater {
            model: root.shown

            Tile {
                required property var modelData
                width: (tileGrid.width - tileGrid.spacing * (tileGrid.columns - 1)) / tileGrid.columns
                height: tileGrid.columns === 1 ? (tileGrid.height - tileGrid.spacing * (root.shown.length - 1)) / root.shown.length : root.tier === "S" ? tileGrid.height : (tileGrid.height - tileGrid.spacing) / 2
                data_: modelData
                m: root
            }
        }
    }

    // L: curves on top, the rest below.
    Item {
        visible: root.tier === "L"
        anchors.fill: parent

        Row {
            id: curves

            width: parent.width
            height: parent.height * 0.62
            spacing: root.gap

            Repeater {
                model: [{ data: root.tiles[0], values: root.cpuHistory }, ...(root.gpu ? [{ data: root.tiles[2], values: root.gpuHistory }] : [])]

                Rectangle {
                    required property var modelData
                    width: (curves.width - curves.spacing) / 2
                    height: curves.height
                    radius: root.theme.radius.tile
                    color: root.theme.color.surface2
                    clip: true

                    Sparkline {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: parent.height * 0.62
                        values: modelData.values
                        max: 1
                    }

                    Header {
                        x: root.gap
                        y: root.gap / 2
                        width: parent.width - root.gap * 2
                        data_: modelData.data
                        m: root
                        big: root.t1 * 0.7
                    }
                }
            }
        }

        Row {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height - curves.height - root.gap
            spacing: root.gap

            Repeater {
                model: root.tiles.filter(t => t.key === "ram" || t.key === "igpu")

                Tile {
                    required property var modelData
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    data_: modelData
                    m: root
                    compact: true
                }
            }
        }
    }

    // Label, figure and detail on one line.
    component Header: Item {
        id: header

        property var data_
        property var m
        property real big: header.m.t1

        height: figure.height

        HeroText {
            id: figure
            text: I18n.percent(header.data_?.value ?? 0)
            pixelSize: header.big
            color: (header.data_?.value ?? 0) > 0.9 ? header.m.theme.color.urgent : header.m.theme.color.ink
        }

        Column {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: header.m.gap / 2

            ThemedText {
                anchors.right: parent.right
                label: true
                text: header.data_?.label ?? ""
                font.pixelSize: header.m.t3
                font.weight: Font.DemiBold
            }

            ThemedText {
                anchors.right: parent.right
                text: header.data_?.detail ?? ""
                font.pixelSize: header.m.t4 * 1.2
                color: header.m.theme.color.soft
            }
        }
    }

    // Figure, label + detail, bar on the bottom edge.
    component Tile: Rectangle {
        id: tile

        property var data_
        property var m
        property bool compact: false
        readonly property real value: data_?.value ?? 0

        radius: tile.m.theme.radius.tile
        color: tile.m.theme.color.surface2

        ThemedText {
            id: label
            x: tile.m.gap * 0.8
            y: tile.m.gap * 0.6
            label: true
            text: tile.data_?.label ?? ""
            font.pixelSize: tile.m.t4 * (tile.m.tier === "S" ? 1 : 1.2)
            font.weight: Font.DemiBold
            color: tile.m.theme.color.soft
        }

        ThemedText {
            anchors.right: parent.right
            anchors.rightMargin: tile.m.gap * 0.8
            y: tile.m.gap * 0.6
            visible: tile.m.tier !== "S" || tile.width > 150
            text: tile.data_?.detail ?? ""
            font.pixelSize: tile.m.t4 * (tile.m.tier === "S" ? 1 : 1.2)
            color: tile.m.theme.color.soft
        }

        HeroText {
            x: tile.m.gap * 0.8
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: label.height * 0.3
            text: I18n.percent(tile.value)
            pixelSize: Math.min(tile.height * (tile.compact ? 0.42 : 0.46), tile.width / 3.2) * tile.m.hk
            color: tile.value > 0.9 ? tile.m.theme.color.urgent : tile.m.theme.color.ink
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: tile.m.gap * 0.8
            height: Math.max(4, tile.height * 0.05)
            radius: height / 2
            color: tile.m.theme.color.surface3

            Rectangle {
                width: parent.width * Math.min(1, tile.value)
                height: parent.height
                radius: parent.radius
                color: tile.value > 0.9 ? tile.m.theme.color.urgent : tile.m.theme.color.accent

                Behavior on width {
                    NumberAnimation {
                        duration: 300
                    }
                }
            }
        }
    }
}
