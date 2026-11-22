import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

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
        { label: "RAM", value: SystemStats.memory, detail: `${SystemStats.memoryUsedGiB.toFixed(1)} / ${Math.round(SystemStats.memoryTotalGiB)} Gio` },
        ...SystemStats.gpus.map((gpu, i) => ({ label: SystemStats.gpus.length > 1 ? `GPU ${i + 1}` : "GPU", value: gpu.busy, detail: gpu.temp ? `${Math.round(gpu.temp)}°` : "" }))
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
                        color: root.theme.color.fgMuted
                    }

                    ThemedText {
                        anchors.right: parent.right
                        text: `${Math.round(modelData.value * 100)} %${modelData.detail ? "  ·  " + modelData.detail : ""}`
                        font.family: root.theme.font.mono
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: root.theme.radius.s
                    color: root.theme.color.surfaceAlt

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
