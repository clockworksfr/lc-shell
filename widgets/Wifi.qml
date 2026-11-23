import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services

// Wi-Fi (hidden without a Wi-Fi interface). Left click: the card (networks,
// join), middle click: power, right click: power.
TextWidget {
    id: root

    readonly property var contextActions: [
        { id: "power", icon: NetworkService.wifiEnabled ? "wifi_off" : "wifi", text: I18n.tr(NetworkService.wifiEnabled ? "ctx.wifiOff" : "ctx.wifiOn") }
    ]
    function contextAction(id: string): void {
        if (id === "power")
            NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
    }

    readonly property bool shown: !!NetworkService.wifi
    readonly property var active: NetworkService.activeWifi
    readonly property real strength: active?.signalStrength ?? 0
    readonly property string value: !NetworkService.wifiEnabled ? I18n.tr("bar.off") : active ? `${Math.round(strength * 100)}` : "—"

    fullText: !NetworkService.wifiEnabled ? I18n.tr("bar.wifiOff")
        : active ? (size === "compact" ? I18n.percent(strength) : `${active.name} ${I18n.percent(strength)}`)
        : I18n.tr("bar.wifi")
    compactText: I18n.tr("bar.v.wifi", { value: root.value })
    microLabel: I18n.tr("bar.v.wifi", { value: "" }).split("\n")[0]
    color: active ? theme.color.ink : theme.color.soft

    icon: !NetworkService.wifiEnabled ? "wifi_off" : !active ? "signal_wifi_off" : strength > 0.66 ? "wifi" : strength > 0.33 ? "wifi_2_bar" : "wifi_1_bar"
    iconText: active && size !== "compact" && !vertical ? (size === "extended" ? `${active.name} · ${I18n.percent(strength)}` : I18n.percent(strength)) : ""

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.MiddleButton ? NetworkService.setWifiEnabled(!NetworkService.wifiEnabled) : ShellState.pinCard(root)
    }

    readonly property bool panelOpen: false

    function togglePanel(): void {
        ShellState.pinCard(root);
    }
}
