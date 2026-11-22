import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Bluetooth status (hidden without an adapter). Click: devices panel.
TextBlock {
    id: root

    readonly property bool shown: BluetoothService.available
    readonly property int count: BluetoothService.connected.length

    fullText: size === "compact" ? compactText.replace("\n", " ")
        : size === "extended" && count > 0 ? `bt · ${BluetoothService.connected.map(d => d.name).join(", ")}`
        : !BluetoothService.enabled ? I18n.tr("bar.bluetoothOff")
        : count > 0 ? I18n.tr("bar.bluetoothCount", { n: count })
        : I18n.tr("bar.bluetooth")
    compactText: !BluetoothService.enabled ? I18n.tr("bar.v.bluetoothOff") : I18n.tr("bar.v.bluetooth", { n: count })
    color: count > 0 ? theme.color.ink : theme.color.soft

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    readonly property bool panelOpen: popup.visible

    function togglePanel(): void {
        popup.toggle();
    }

    BarPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: BluetoothService.discoveryRequests += visible ? 1 : -1

        BluetoothPanel {}
    }
}
