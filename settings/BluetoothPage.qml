import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services
import qs.theme

// Bluetooth: power and devices; searches while open, a click pairs a new
// device (then trusted and connected), connects or disconnects a known one.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Component.onCompleted: BluetoothService.discoveryRequests++
    Component.onDestruction: BluetoothService.discoveryRequests--

    spacing: theme.space.s

    Section {
        title: I18n.tr("btset.devices")

        BluetoothPanel {
            width: parent.width
        }
    }
}
