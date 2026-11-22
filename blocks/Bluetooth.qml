import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Bluetooth status (hidden without an adapter). Click: devices panel.
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    readonly property bool shown: BluetoothService.available

    text: !BluetoothService.enabled ? I18n.tr("bar.bluetoothOff")
        : BluetoothService.connected.length > 0 ? I18n.tr("bar.bluetoothCount", { n: BluetoothService.connected.length })
        : I18n.tr("bar.bluetooth")
    color: BluetoothService.connected.length > 0 ? theme.color.ink : theme.color.soft

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible = !popup.visible
    }

    BarPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: BluetoothService.discoveryRequests += visible ? 1 : -1

        BluetoothPanel {}
    }
}
