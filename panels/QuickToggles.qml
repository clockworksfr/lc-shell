pragma Singleton

import QtQuick
import Quickshell
import qs.i18n
import qs.lock
import qs.services
import qs.theme

// The quick settings' switches, shared by the dashboard's Toggles module
// and the bar's quick settings panel: tiles ({ id, icon, label, short,
// sub, on, placeholder }) and what tapping one does.
Singleton {
    readonly property var tiles: [
        {
            id: "dnd",
            icon: "do_not_disturb_on",
            label: I18n.tr("toggles.dnd"),
            short: I18n.tr("toggles.dndShort"),
            sub: NotificationCenter.dnd ? I18n.tr("toggles.on") : "",
            on: NotificationCenter.dnd
        },
        {
            id: "mic",
            icon: Audio.sourceMuted ? "mic_off" : "mic",
            label: I18n.tr("toggles.mic"),
            sub: Audio.sourceMuted ? I18n.tr("common.muted") : I18n.percent(Audio.sourceVolume),
            on: !Audio.sourceMuted
        },
        {
            id: "wifi",
            icon: NetworkService.wifiEnabled ? "wifi" : "wifi_off",
            label: I18n.tr("toggles.wifi"),
            sub: NetworkService.activeWifi?.name ?? "",
            on: NetworkService.wifiEnabled
        },
        {
            id: "bluetooth",
            icon: BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled",
            label: I18n.tr("toggles.bluetooth"),
            sub: BluetoothService.devices.filter(d => d.connected).map(d => d.name).join(", "),
            on: BluetoothService.enabled
        },
        {
            id: "dark",
            icon: "dark_mode",
            label: I18n.tr("toggles.dark"),
            sub: Themes.variantMode === "auto" ? I18n.tr("toggles.auto") : "",
            on: Themes.variant === "dark"
        },
        {
            id: "vpn",
            icon: VpnService.active ? "vpn_lock" : "vpn_key",
            label: I18n.tr("toggles.vpn"),
            sub: VpnService.current?.name ?? I18n.tr("toggles.noVpn"),
            on: VpnService.active,
            placeholder: !VpnService.available
        },
        {
            id: "caffeine",
            icon: "coffee",
            label: I18n.tr("toggles.caffeine"),
            sub: Idle.caffeine ? I18n.tr("toggles.awake") : "",
            on: Idle.caffeine
        },
        {
            id: "record",
            icon: "screen_record",
            label: I18n.tr("toggles.record"),
            sub: I18n.tr("toggles.soon"),
            on: false,
            placeholder: true
        }
    ]

    function activate(id: string): void {
        switch (id) {
        case "dnd":
            NotificationCenter.setDnd(!NotificationCenter.dnd);
            break;
        case "mic":
            Audio.toggleSourceMute();
            break;
        case "wifi":
            NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
            break;
        case "bluetooth":
            BluetoothService.setEnabled(!BluetoothService.enabled);
            break;
        case "dark":
            Themes.toggleVariant();
            break;
        case "vpn":
            VpnService.toggle();
            break;
        case "caffeine":
            Idle.caffeine = !Idle.caffeine;
            break;
        }
    }
}
