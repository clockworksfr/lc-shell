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
        model: BluetoothService.enabled ? BluetoothService.devices.filter(d => d.paired || !!d.name).slice(0, 14) : []

        ListRow {
            required property var modelData

            title: modelData.name || I18n.tr("bt.unnamed")
            subtitle: modelData.pairing ? I18n.tr("bt.pairing")
                : modelData.state === BluetoothDeviceState.Connecting ? I18n.tr("bt.connecting")
                : modelData.connected ? I18n.tr("bt.connected")
                : modelData.paired ? I18n.tr("bt.paired") : ""
            trailing: modelData.batteryAvailable ? I18n.percent(modelData.battery) : ""
            selected: modelData.connected
            dimmed: !modelData.paired && !modelData.connected
            onClicked: BluetoothService.toggleConnection(modelData)
        }
    }
}
