import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Bluetooth switch and devices. Click: connect / disconnect, or pair a
// new device (it is then trusted and connected).
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // Settings: devices not paired go under "Nearby devices (n)".
    property bool foldNearby: false
    property bool unfolded: false
    function unnamed(device: var): bool {
        return !device.name || /^([0-9A-F]{2}[:-]){5}[0-9A-F]{2}$/i.test(device.name);
    }
    readonly property var all: BluetoothService.enabled ? BluetoothService.devices.filter(d => d.paired || d.connected || !!d.name) : []
    readonly property var known: all.filter(d => d.paired || d.connected)
    readonly property var nearby: all.filter(d => !d.paired && !d.connected).sort((a, b) => unnamed(a) - unnamed(b))
    readonly property var shown: foldNearby ? [...known, ...(unfolded ? nearby : [])].slice(0, 30) : all.slice(0, 14)

    width: 360
    spacing: theme.space.s

    Switch {
        text: I18n.tr("bt.title")
        checked: BluetoothService.enabled
        available: BluetoothService.available
        onToggled: BluetoothService.setEnabled(!checked)
    }

    ThemedText {
        visible: BluetoothService.enabled
        text: BluetoothService.adapter?.discovering ? I18n.tr("bt.searching") : ""
        color: root.theme.color.soft
        font.pixelSize: root.theme.font.sizeS
    }

    Repeater {
        model: root.shown

        ListRow {
            required property var modelData

            title: root.unnamed(modelData) ? I18n.tr("bt.unknown") : modelData.name
            subtitle: modelData.pairing ? I18n.tr("bt.pairing")
                : modelData.state === BluetoothDeviceState.Connecting ? I18n.tr("bt.connecting")
                : modelData.connected ? I18n.tr("bt.connected")
                : modelData.paired ? I18n.tr("bt.paired")
                : root.unnamed(modelData) ? (modelData.address ?? "") : ""
            trailing: modelData.batteryAvailable ? I18n.percent(modelData.battery) : ""
            selected: modelData.connected
            dimmed: !modelData.paired && !modelData.connected
            onClicked: BluetoothService.toggleConnection(modelData)
        }
    }

    ListRow {
        visible: root.foldNearby && root.nearby.length > 0
        title: I18n.tr(root.unfolded ? "card.lessDevices" : "bt.nearby", { n: root.nearby.length })
        trailing: root.unfolded ? "⌃" : "›"
        onClicked: root.unfolded = !root.unfolded
    }
}
