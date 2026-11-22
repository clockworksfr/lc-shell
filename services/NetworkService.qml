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
    // Interfaces with traffic to show (wired and Wi-Fi devices).
    readonly property var interfaces: devices.filter(d => d.type === DeviceType.Wired || d.type === DeviceType.Wifi).map(d => ({ name: d.name, wifi: d.type === DeviceType.Wifi, connected: d.connected }))
    // Traffic source: "auto" (the active interface), "all" (every
    // interface added up) or an interface name. Kept in the settings.
    readonly property string source: Config.get("network.trafficSource") ?? "auto"
    readonly property var sourceNames: source === "auto" ? (iface ? [iface] : [])
        : source === "all" ? interfaces.map(i => i.name)
        : [source]
    function setSource(value: string): void {
        Config.set("network.trafficSource", value === "auto" ? undefined : value);
    }

    // Bytes per second, and the last 60 samples (1/s) of each, for the source.
    property real rxRate: 0
    property real txRate: 0
    property var rxHistory: []
    property var txHistory: []
    property string address
    // Last counters per interface: { time, counters: { name: { rx, tx } } }.
    property var lastBytes: null

    onSourceNamesChanged: {
        rxHistory = [];
        txHistory = [];
        rxRate = 0;
        txRate = 0;
    }
    onIfaceChanged: if (watchers > 0) addressProc.running = true
    onWatchersChanged: if (watchers > 0) addressProc.running = true

    Timer {
        interval: 1000
        repeat: true
        // Always on (one small procfs read per second): the curves are
        // already filled when a card opens.
        running: root.interfaces.length > 0
        triggeredOnStart: true
        onTriggered: netDev.reload()
    }

    // Every interface's counters in one file.
    FileView {
        id: netDev
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: {
            const now = Date.now();
            const counters = {};
            for (const line of text().split("\n").slice(2)) {
                const m = /^\s*([^:]+):\s*(.*)$/.exec(line);
                if (!m)
                    continue;
                const f = m[2].trim().split(/\s+/);
                counters[m[1]] = { rx: Number(f[0]), tx: Number(f[8]) };
            }
            const last = root.lastBytes;
            if (last) {
                const seconds = Math.max(0.001, (now - last.time) / 1000);
                let rx = 0, tx = 0;
                for (const name of root.sourceNames) {
                    const a = last.counters[name], b = counters[name];
                    // An interface that (re)appeared: no delta yet.
                    if (a && b) {
                        rx += Math.max(0, b.rx - a.rx);
                        tx += Math.max(0, b.tx - a.tx);
                    }
                }
                root.rxRate = rx / seconds;
                root.txRate = tx / seconds;
                root.rxHistory = [...root.rxHistory, root.rxRate].slice(-60);
                root.txHistory = [...root.txHistory, root.txRate].slice(-60);
            }
            root.lastBytes = { time: now, counters: counters };
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
