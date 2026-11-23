import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Output volume. Left click: audio panel (volume, devices),
// middle click: mute, wheel: volume.
TextWidget {
    id: root

    // Right-click menu (the bar's widget menu).
    readonly property var contextActions: [
        { id: "mute", icon: Audio.muted ? "volume_up" : "volume_off", text: I18n.tr(Audio.muted ? "ctx.unmute" : "ctx.mute") },
        { id: "mic", icon: Audio.sourceMuted ? "mic" : "mic_off", text: I18n.tr(Audio.sourceMuted ? "ctx.micOn" : "ctx.micOff") }
    ]
    function contextAction(id: string): void {
        if (id === "mute")
            Audio.toggleMute();
        else if (id === "mic")
            Audio.toggleSourceMute();
    }

    fullText: Audio.muted ? I18n.tr("common.muted")
        : size === "compact" ? I18n.percent(Audio.volume)
        : size === "extended" ? (Screens.sharing ? I18n.percent(Audio.volume) : `${Audio.sinkName} · ${I18n.percent(Audio.volume)}`)
        : I18n.tr("bar.volume", { value: Math.round(Audio.volume * 100) })
    // Extended (device · level): "SON" over it, like BT / BAT.
    microLabel: I18n.tr("bar.v.volume", { value: "" }).split("\n")[0]
    compactText: Audio.muted ? I18n.tr("common.muted") : I18n.tr("bar.v.volume", { value: Math.round(Audio.volume * 100) })
    color: Audio.muted ? theme.color.soft : theme.color.ink

    icon: Audio.muted ? "volume_off" : Audio.volume > 0.66 ? "volume_up" : Audio.volume > 0.01 ? "volume_down" : "volume_mute"
    iconFilled: true
    iconText: Audio.muted || size === "compact" ? "" : size === "extended" ? (Screens.sharing ? I18n.percent(Audio.volume) : `${Audio.sinkName} · ${I18n.percent(Audio.volume)}`) : I18n.percent(Audio.volume)

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Audio.toggleMute();
            else
                ShellState.pinCard(root);
        }
        onWheel: wheel => wheel.angleDelta.y > 0 ? Audio.increment() : Audio.decrement()
    }

    readonly property bool panelOpen: false

    function togglePanel(): void {
        ShellState.pinCard(root);
    }
}
