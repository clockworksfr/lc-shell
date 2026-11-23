import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Bluetooth: power, devices (connected first, battery), connect or
// disconnect in one click; search, then pair new devices.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var known: BluetoothService.devices.filter(d => d.paired || d.connected)
    readonly property var found: BluetoothService.devices.filter(d => !d.paired && !d.connected && !!d.name)

    // Searching while asked, and only while the card is open.
    property bool scanning: false
    onScanningChanged: BluetoothService.discoveryRequests += scanning ? 1 : -1
    Component.onDestruction: if (scanning) BluetoothService.discoveryRequests -= 1
    Connections {
        target: root.QsWindow.window
        function onPhaseChanged(): void {
            if (root.QsWindow.window?.phase === "")
                root.scanning = false;
        }
    }

    function iconOf(device: var): string {
        const i = device.icon ?? "";
        return i.includes("headset") || i.includes("headphone") ? "headphones"
            : i.includes("speaker") || i.includes("audio") ? "speaker"
            : i.includes("mouse") ? "mouse"
            : i.includes("keyboard") ? "keyboard"
            : i.includes("phone") ? "mobile"
            : i.includes("gaming") ? "sports_esports"
            : i.includes("watch") ? "watch"
            : "bluetooth";
    }

    spacing: 4

    CardParts.Header {
        title: I18n.tr("bt.title")
        status: !BluetoothService.available ? I18n.tr("card.noAdapter")
            : !BluetoothService.enabled ? I18n.tr("qs.off")
            : BluetoothService.connected.length > 0 ? I18n.tr("card.btConnected", { n: BluetoothService.connected.length })
            : I18n.tr("card.on")
        checked: BluetoothService.enabled
        available: BluetoothService.available
        onToggled: BluetoothService.setEnabled(!BluetoothService.enabled)
    }

    Item {
        width: 1
        height: 4
    }

    Repeater {
        model: BluetoothService.enabled ? root.known.slice(0, 8) : []

        CardParts.Line {
            required property var modelData
            readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

            icon: root.iconOf(modelData)
            title: modelData.name || I18n.tr("bt.unnamed")
            readonly property bool low: modelData.batteryAvailable && (modelData.battery ?? 1) < 0.2
            sub: [busy ? I18n.tr("bt.connecting") : modelData.connected ? I18n.tr("bt.connected") : I18n.tr("bt.paired"), modelData.batteryAvailable ? I18n.percent(modelData.battery ?? 0) : "", low ? I18n.tr("card.charge") : ""].filter(t => !!t).join(" · ")
            subColor: low ? (root.theme.color.warn ?? root.theme.color.urgent) : root.theme.color.soft
            active: modelData.connected
            control: "button"
            buttonText: I18n.tr(modelData.connected ? "card.disconnect" : "card.connect")
            battery: modelData.batteryAvailable ? (modelData.battery ?? 0) : -1
            onPressed: BluetoothService.toggleConnection(modelData)
        }
    }

    CardParts.Line {
        visible: BluetoothService.enabled
        icon: "bluetooth_searching"
        title: I18n.tr(root.scanning ? "bt.searching" : "card.newDevices")
        sub: root.scanning ? I18n.tr("card.found", { n: root.found.length }) : I18n.tr("card.searchSub")
        active: root.scanning
        control: "button"
        buttonText: I18n.tr(root.scanning ? "card.stop" : "card.search")
        onPressed: root.scanning = !root.scanning
    }

    Repeater {
        model: root.scanning ? root.found.slice(0, 6) : []

        CardParts.Line {
            required property var modelData

            icon: root.iconOf(modelData)
            title: modelData.name
            sub: modelData.pairing ? I18n.tr("bt.pairing") : I18n.tr("card.new")
            dimmed: modelData.pairing
            control: "button"
            buttonText: I18n.tr("card.pair")
            onPressed: BluetoothService.toggleConnection(modelData)
        }
    }

    Item {
        width: 1
        height: 6
    }

    CardParts.Footer {
        page: "bluetooth"
        pageName: I18n.tr("bt.title")
        hints: I18n.tr("card.hintsBluetooth")
    }
}
