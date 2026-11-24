import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Network status. Click: network panel (Wi-Fi list, wired state).
TextWidget {
    id: root

    // The rate changes every second: never move the neighbours.
    stableWidth: true

    // Right-click menu (the bar's widget menu).
    readonly property var contextActions: [
        ...(NetworkService.wifi ? [{ id: "wifi", icon: NetworkService.wifiEnabled ? "wifi_off" : "wifi", text: I18n.tr(NetworkService.wifiEnabled ? "ctx.wifiOff" : "ctx.wifiOn") }] : []),
        ...(VpnService.available ? [{ id: "vpn", icon: "vpn_key", text: I18n.tr(VpnService.active ? "ctx.vpnOff" : "ctx.vpnOn", { name: VpnService.current.name }) }] : [])
    ]
    function contextAction(id: string): void {
        if (id === "wifi")
            NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
        else if (id === "vpn")
            VpnService.toggle();
    }

    // Traffic sampled for the bar (Matrix: NET / ↓1,2M).
    Component.onCompleted: NetworkService.watchers++
    Component.onDestruction: NetworkService.watchers--
    function shortRate(value: real): string {
        const units = ["", "K", "M", "G"];
        let unit = 0;
        let v = Math.max(0, value);
        while (v >= 1000 && unit < units.length - 1) {
            v /= 1000;
            unit++;
        }
        return `${I18n.number(v, v < 10 && unit > 0 ? 1 : 0)}${units[unit]}`;
    }

    readonly property string signal: NetworkService.activeWifi ? I18n.percent(NetworkService.activeWifi.signalStrength) : ""
    // A VPN up: the quick settings' one, or any NetworkManager VPN.
    readonly property bool vpn: VpnService.active || VpnService.activeNames.length > 0

    readonly property string label: NetworkService.kind === "wired" ? I18n.tr("net.wired")
        : NetworkService.kind === "wifi" ? `${(Screens.sharing ? I18n.tr("toggles.wifi") : NetworkService.activeWifi.name)} ${signal}`
        : I18n.tr("net.offline")

    fullText: (size === "extended" && NetworkService.kind !== "none" ? `${label} · ↓ ${I18n.bytes(NetworkService.rxRate, true)}`
        : NetworkService.kind === "wired" ? I18n.tr("net.wired")
        : NetworkService.kind === "wifi" ? `${(Screens.sharing ? I18n.tr("toggles.wifi") : NetworkService.activeWifi.name)} ${signal}`
        : I18n.tr("net.offline")) + (vpn ? " · VPN" : "")
    // Matrix micro labels: NET over the download rate (and VPN).
    compactText: labelled && !vertical && size !== "compact"
        ? I18n.tr("bar.v.net", { value: NetworkService.kind === "none" ? "—" : `↓${shortRate(NetworkService.rxRate)}${vpn ? " · VPN" : ""}` })
        : vpn ? I18n.tr("bar.v.vpn", { value: NetworkService.kind === "wired" ? "eth" : NetworkService.kind === "wifi" ? signal : "—" })
        : NetworkService.kind === "wired" ? I18n.tr("bar.v.wired")
        : NetworkService.kind === "wifi" ? I18n.tr("bar.v.wifi", { value: signal })
        : I18n.tr("bar.v.offline")
    color: NetworkService.kind === "none" ? theme.color.soft : theme.color.ink

    readonly property real strength: NetworkService.activeWifi?.signalStrength ?? 0
    icon: vpn ? "vpn_lock"
        : NetworkService.kind === "wired" ? "lan"
        : NetworkService.kind === "wifi" ? (strength > 0.66 ? "wifi" : strength > 0.33 ? "wifi_2_bar" : "wifi_1_bar")
        : "signal_wifi_off"
    iconText: size === "compact" ? ""
        : size === "extended" && NetworkService.kind !== "none" ? `${NetworkService.kind === "wifi" ? (Screens.sharing ? I18n.tr("toggles.wifi") : NetworkService.activeWifi.name) + " · " : ""}↓ ${I18n.bytes(NetworkService.rxRate, true)}`
        : NetworkService.kind === "wifi" && !vertical ? (Screens.sharing ? I18n.tr("toggles.wifi") : NetworkService.activeWifi.name)
        : ""

    // Left: the card, pinned. Middle: the chosen VPN. Wheel: traffic source.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.MiddleButton ? (VpnService.available && VpnService.toggle()) : ShellState.pinCard(root)
        onWheel: wheel => {
            const sources = ["auto", "all", ...NetworkService.interfaces.map(i => i.name)];
            const i = sources.indexOf(NetworkService.source);
            NetworkService.setSource(sources[(i + (wheel.angleDelta.y > 0 ? -1 : 1) + sources.length) % sources.length]);
        }
    }

    readonly property bool panelOpen: false

    function togglePanel(): void {
        ShellState.pinCard(root);
    }
}
