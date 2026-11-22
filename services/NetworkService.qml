pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Network state and actions (NetworkManager through Quickshell.Networking).
Singleton {
    id: root

    readonly property list<NetworkDevice> devices: Networking.devices.values
    // Several adapters can exist (dock, USB dongle): prefer a connected one.
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired)
    readonly property var wifiDevices: devices.filter(d => d.type === DeviceType.Wifi)
    readonly property var wired: wiredDevices.find(d => d.connected) ?? wiredDevices[0] ?? null
    readonly property var wifi: wifiDevices.find(d => d.connected) ?? wifiDevices[0] ?? null

    readonly property bool wiredConnected: wired?.connected ?? false
    readonly property var wifiNetworks: wifi ? wifi.networks.values.slice().sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength)) : []
    readonly property var activeWifi: wifiNetworks.find(n => n.connected) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    // "wired" | "wifi" | "none"
    readonly property string kind: wiredConnected ? "wired" : activeWifi ? "wifi" : "none"
    readonly property bool online: Networking.connectivity === NetworkConnectivity.Full || Networking.connectivity === NetworkConnectivity.Unknown && kind !== "none"

    // Number of panels asking for fresh scan results.
    property int scanRequests: 0

    Binding {
        target: root.wifi
        property: "scannerEnabled"
        value: root.scanRequests > 0
        when: !!root.wifi
    }

    function setWifiEnabled(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    function isSecured(network: var): bool {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Unknown;
    }

    // Known or open networks connect directly; others need the passphrase.
    function connect(network: var, psk: string): void {
        if (psk)
            network.connectWithPsk(psk);
        else
            network.connect();
    }

    function disconnect(network: var): void {
        network.disconnect();
    }

    function forget(network: var): void {
        network.forget();
    }
}
