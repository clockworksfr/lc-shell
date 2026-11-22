import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme
import qs.i18n

// CPU, memory, GPU(s) load and temperatures.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Component.onCompleted: SystemStats.refCount++
    Component.onDestruction: SystemStats.refCount--

    readonly property var rows: [
        { label: "CPU", value: SystemStats.cpu, detail: SystemStats.cpuTemp ? `${Math.round(SystemStats.cpuTemp)}°` : "" },
        { label: "RAM", value: SystemStats.memory, detail: I18n.tr("system.memory", { used: I18n.number(SystemStats.memoryUsedGiB, 1), total: Math.round(SystemStats.memoryTotalGiB) }) },
        ...SystemStats.gpus.map(gpu => ({ label: SystemStats.gpus.length > 1 ? I18n.tr(gpu.integrated ? "system.gpuIntegrated" : "system.gpuDiscrete") : "GPU", value: gpu.busy, detail: gpu.temp ? `${Math.round(gpu.temp)}°` : "" }))
    ]

    Column {
        anchors.fill: parent
        spacing: root.theme.space.m

        Repeater {
            model: root.rows

            Column {
                required property var modelData

                width: parent.width
                spacing: root.theme.space.xs

                Item {
                    width: parent.width
                    implicitHeight: name.implicitHeight

                    ThemedText {
                        id: name
                        label: true
                        text: modelData.label
                        color: root.theme.color.soft
                    }

                    ThemedText {
                        anchors.right: parent.right
                        text: I18n.percent(modelData.value) + (modelData.detail ? "  ·  " + modelData.detail : "")
                        font.family: root.theme.font.mono
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: root.theme.radius.full
                    color: root.theme.color.surface2

                    Rectangle {
                        width: parent.width * Math.min(1, modelData.value)
                        height: parent.height
                        radius: parent.radius
                        color: modelData.value > 0.9 ? root.theme.color.urgent : root.theme.color.accent

                        Behavior on width {
                            NumberAnimation {
                                duration: 300
                            }
                        }
                    }
                }
            }
        }
    }
}
