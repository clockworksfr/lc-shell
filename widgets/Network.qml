import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Network status. Click: network panel (Wi-Fi list, wired state).
TextWidget {
    id: root

    readonly property string signal: NetworkService.activeWifi ? I18n.percent(NetworkService.activeWifi.signalStrength) : ""

    readonly property string label: NetworkService.kind === "wired" ? I18n.tr("net.wired")
        : NetworkService.kind === "wifi" ? `${NetworkService.activeWifi.name} ${signal}`
        : I18n.tr("net.offline")

    fullText: size === "extended" && NetworkService.kind !== "none" ? `${label} · ↓ ${I18n.bytes(NetworkService.rxRate, true)}`
        : NetworkService.kind === "wired" ? I18n.tr("net.wired")
        : NetworkService.kind === "wifi" ? `${NetworkService.activeWifi.name} ${signal}`
        : I18n.tr("net.offline")
    compactText: NetworkService.kind === "wired" ? I18n.tr("bar.v.wired")
        : NetworkService.kind === "wifi" ? I18n.tr("bar.v.wifi", { value: signal })
        : I18n.tr("bar.v.offline")
    color: NetworkService.kind === "none" ? theme.color.soft : theme.color.ink

    readonly property real strength: NetworkService.activeWifi?.signalStrength ?? 0
    icon: NetworkService.kind === "wired" ? "lan"
        : NetworkService.kind === "wifi" ? (strength > 0.66 ? "wifi" : strength > 0.33 ? "wifi_2_bar" : "wifi_1_bar")
        : "signal_wifi_off"
    iconText: size === "compact" ? ""
        : size === "extended" && NetworkService.kind !== "none" ? `${NetworkService.kind === "wifi" ? NetworkService.activeWifi.name + " · " : ""}↓ ${I18n.bytes(NetworkService.rxRate, true)}`
        : NetworkService.kind === "wifi" && !vertical ? NetworkService.activeWifi.name
        : ""

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    readonly property bool panelOpen: popup.visible

    function togglePanel(): void {
        popup.toggle();
    }

    BarPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: NetworkService.scanRequests += visible ? 1 : -1

        NetworkPanel {}
    }
}
