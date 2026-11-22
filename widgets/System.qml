import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services

// CPU load (compact), + GPU (normal), + temperatures and memory
// (extended). Red above 90 %. Click: the system monitor
// (system.monitorCommand, default kitty -e btop). Detail in the card.
TextWidget {
    id: root

    Component.onCompleted: SystemStats.refCount++
    Component.onDestruction: SystemStats.refCount--

    readonly property var gpu: SystemStats.gpus.find(g => !g.integrated) ?? SystemStats.gpus[0] ?? null
    readonly property string cpu: I18n.percent(SystemStats.cpu)
    readonly property string gpuText: gpu ? I18n.percent(gpu.busy) : ""
    readonly property bool hot: SystemStats.cpu > 0.9 || (gpu?.busy ?? 0) > 0.9

    fullText: size === "compact" ? `CPU ${cpu}`
        : size === "extended" ? [`CPU ${cpu}${SystemStats.cpuTemp ? ` ${Math.round(SystemStats.cpuTemp)}°` : ""}`, gpu ? `GPU ${gpuText}${gpu.temp ? ` ${Math.round(gpu.temp)}°` : ""}` : "", `RAM ${I18n.percent(SystemStats.memory)}`].filter(s => !!s).join(" · ")
        : [`CPU ${cpu}`, gpu ? `GPU ${gpuText}` : ""].filter(s => !!s).join(" · ")
    compactText: I18n.tr("bar.v.cpu", { value: Math.round(SystemStats.cpu * 100) })
    color: hot ? theme.color.urgent : theme.color.ink

    icon: "memory"
    iconText: size === "compact" || vertical ? `${Math.round(SystemStats.cpu * 100)}` : fullText

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(Config.get("system.monitorCommand") ?? ["kitty", "-e", "btop"])
    }
}
