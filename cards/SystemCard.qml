import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.i18n
import qs.services
import qs.theme

// CPU and GPU (load, temperature, last minute), memory, the 3 busiest
// processes. Click a process: nothing (read-only); the widget opens btop.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Component.onCompleted: SystemStats.refCount++
    Component.onDestruction: SystemStats.refCount--

    readonly property var gpu: SystemStats.gpus.find(g => !g.integrated) ?? SystemStats.gpus[0] ?? null
    property var processes: []

    spacing: theme.space.m

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!top.running)
                top.running = true;
        }
    }

    // Busiest processes (name, CPU %).
    Process {
        id: top
        command: ["ps", "-eo", "comm=,pcpu=", "--sort=-pcpu"]
        stdout: StdioCollector {
            onStreamFinished: root.processes = text.trim().split("\n").slice(0, 3).map(l => {
                const m = /^(.*\S)\s+([\d.]+)$/.exec(l.trim());
                return m ? { name: m[1], cpu: parseFloat(m[2]) } : null;
            }).filter(p => !!p)
        }
    }

    Row {
        width: parent.width
        spacing: root.theme.space.s

        Repeater {
            model: [
                { label: "CPU", value: SystemStats.cpu, temp: SystemStats.cpuTemp, values: SystemStats.cpuHistory },
                ...(root.gpu ? [{ label: "GPU", value: root.gpu.busy, temp: root.gpu.temp, values: SystemStats.gpuHistory }] : [])
            ]

            Rectangle {
                required property var modelData
                width: (parent.width - root.theme.space.s) / 2
                height: 110
                radius: root.theme.radius.tile
                color: root.theme.color.surface2
                clip: true

                Sparkline {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 44
                    values: modelData.values
                    max: 1
                }

                ThemedText {
                    x: root.theme.space.m
                    y: root.theme.space.s
                    label: true
                    text: modelData.label
                    color: root.theme.color.soft
                }

                ThemedText {
                    anchors.right: parent.right
                    anchors.rightMargin: root.theme.space.m
                    y: root.theme.space.s
                    visible: modelData.temp > 0
                    text: `${Math.round(modelData.temp)}°`
                    color: root.theme.color.soft
                }

                HeroText {
                    x: root.theme.space.m
                    y: root.theme.space.s + 18
                    text: I18n.percent(modelData.value)
                    pixelSize: 30
                    color: modelData.value > 0.9 ? root.theme.color.urgent : root.theme.color.nixie ?? root.theme.color.ink
                }
            }
        }
    }

    // Memory.
    Column {
        width: parent.width
        spacing: root.theme.space.xs

        Item {
            width: parent.width
            height: memLabel.implicitHeight

            ThemedText {
                id: memLabel
                label: true
                text: "RAM"
                color: root.theme.color.soft
            }

            ThemedText {
                anchors.right: parent.right
                text: I18n.tr("system.memory", { used: I18n.number(SystemStats.memoryUsedGiB, 1), total: Math.round(SystemStats.memoryTotalGiB) })
            }
        }

        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: root.theme.color.surface3

            Rectangle {
                width: parent.width * Math.min(1, SystemStats.memory)
                height: parent.height
                radius: parent.radius
                color: SystemStats.memory > 0.9 ? root.theme.color.urgent : root.theme.color.accent
            }
        }
    }

    // Busiest processes.
    Column {
        visible: root.processes.length > 0
        width: parent.width
        spacing: root.theme.space.xs

        ThemedText {
            label: true
            text: I18n.tr("system.processes")
            color: root.theme.color.soft
        }

        Repeater {
            model: root.processes

            Item {
                required property var modelData
                width: parent.width
                height: procName.implicitHeight

                ThemedText {
                    id: procName
                    width: parent.width - procCpu.width - root.theme.space.m
                    elide: Text.ElideRight
                    text: modelData.name
                }

                ThemedText {
                    id: procCpu
                    anchors.right: parent.right
                    text: I18n.percent(modelData.cpu / 100)
                    font.family: root.theme.font.mono
                    color: root.theme.color.soft
                }
            }
        }
    }

    ThemedText {
        width: parent.width
        wrapMode: Text.WordWrap
        text: I18n.tr("system.openMonitor")
        color: root.theme.color.soft
        font.pixelSize: root.theme.font.sizeS
    }
}
