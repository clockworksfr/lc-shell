pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth state and actions (BlueZ through Quickshell.Bluetooth).
Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: !!adapter
    readonly property bool enabled: adapter?.enabled ?? false

    // Connected first, then paired, then by name; unnamed devices last.
    readonly property var devices: (adapter?.devices.values ?? []).slice().sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || (!!b.name - !!a.name) || (a.name ?? "").localeCompare(b.name ?? ""))
    readonly property var connected: devices.filter(d => d.connected)

    // Number of panels asking for discovery of new devices.
    property int discoveryRequests: 0

    Binding {
        target: root.adapter
        property: "discovering"
        value: root.discoveryRequests > 0 && root.enabled
        when: !!root.adapter
    }

    function setEnabled(enabled: bool): void {
        if (adapter)
            adapter.enabled = enabled;
    }

    function toggleConnection(device: var): void {
        if (device.connected)
            device.disconnect();
        else if (device.paired)
            device.connect();
        else {
            // New device: pair, trust (auto-reconnect), then connect.
            device.trusted = true;
            device.pair();
        }
    }

    // A freshly paired device connects as soon as pairing completes.
    Instantiator {
        model: root.adapter?.devices ?? null

        Connections {
            required property var modelData
            target: modelData

            function onPairedChanged(): void {
                if (modelData.paired && !modelData.connected)
                    modelData.connect();
            }
        }
    }
}
