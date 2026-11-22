pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
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

    // --- Traffic and address (sampled while `watchers` > 0) ---

    property int watchers: 0
    // Active interface (wired first).
    readonly property string iface: (wiredConnected ? wired?.name : activeWifi ? wifi?.name : "") ?? ""
    // Bytes per second, and the last 60 samples (1/s) of each.
    property real rxRate: 0
    property real txRate: 0
    property var rxHistory: []
    property var txHistory: []
    property string address
    property var lastBytes: null

    onIfaceChanged: {
        lastBytes = null;
        rxHistory = [];
        txHistory = [];
        if (watchers > 0)
            addressProc.running = true;
    }
    onWatchersChanged: if (watchers > 0) addressProc.running = true

    Timer {
        interval: 1000
        repeat: true
        running: root.watchers > 0 && root.iface !== ""
        triggeredOnStart: true
        onTriggered: rxFile.reload()
    }

    FileView {
        id: rxFile
        path: root.iface ? `/sys/class/net/${root.iface}/statistics/rx_bytes` : ""
        printErrors: false
        onLoaded: txFile.reload()
    }

    FileView {
        id: txFile
        path: root.iface ? `/sys/class/net/${root.iface}/statistics/tx_bytes` : ""
        printErrors: false
        onLoaded: {
            const now = Date.now();
            const rx = Number(rxFile.text());
            const tx = Number(text());
            if (root.lastBytes) {
                const seconds = Math.max(0.001, (now - root.lastBytes.time) / 1000);
                root.rxRate = Math.max(0, (rx - root.lastBytes.rx) / seconds);
                root.txRate = Math.max(0, (tx - root.lastBytes.tx) / seconds);
                root.rxHistory = [...root.rxHistory, root.rxRate].slice(-60);
                root.txHistory = [...root.txHistory, root.txRate].slice(-60);
            }
            root.lastBytes = { time: now, rx: rx, tx: tx };
        }
    }

    Process {
        id: addressProc
        command: ["ip", "-j", "-4", "addr", "show", "dev", root.iface]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.address = JSON.parse(text)[0]?.addr_info?.[0]?.local ?? "";
                } catch (e) {
                    root.address = "";
                }
            }
        }
    }
}
