import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Bluetooth status (hidden without an adapter). Click: devices panel.
TextWidget {
    id: root

    // Right-click menu (the bar's widget menu).
    readonly property var contextActions: [
        { id: "power", icon: BluetoothService.enabled ? "bluetooth_disabled" : "bluetooth", text: I18n.tr(BluetoothService.enabled ? "ctx.btOff" : "ctx.btOn") }
    ]
    function contextAction(id: string): void {
        if (id === "power")
            BluetoothService.setEnabled(!BluetoothService.enabled);
    }

    readonly property bool shown: BluetoothService.available
    readonly property int count: BluetoothService.connected.length

    // Lowest battery of the connected devices ("" = none reported).
    readonly property string lowest: {
        const levels = BluetoothService.connected.filter(d => d.batteryAvailable).map(d => d.battery ?? 1);
        return levels.length ? I18n.percent(Math.min(...levels)) : "";
    }
    readonly property string names: [BluetoothService.connected.map(d => d.name).join(", "), lowest].filter(t => !!t).join(" · ")
    // Extended in Matrix: BT over the names and the lowest battery.
    microLabel: I18n.tr("bar.v.bluetooth", { n: "" }).split("\n")[0]

    fullText: size === "extended" && count > 0 ? (theme.style.statusStack === true ? names : `bt · ${names}`)
        : !BluetoothService.enabled ? I18n.tr("bar.bluetoothOff")
        : count > 0 ? I18n.tr("bar.bluetoothCount", { n: count })
        : I18n.tr("bar.bluetooth")
    compactText: !BluetoothService.enabled ? I18n.tr("bar.v.bluetoothOff") : I18n.tr("bar.v.bluetooth", { n: count })
    color: count > 0 ? theme.color.ink : theme.color.soft

    icon: !BluetoothService.enabled ? "bluetooth_disabled" : count > 0 ? "bluetooth_connected" : "bluetooth"
    iconText: !BluetoothService.enabled || count === 0 || size === "compact" ? ""
        : size === "extended" && !vertical ? names
        : `${count}`

    // Left: the card, pinned. Middle: power.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.MiddleButton ? BluetoothService.setEnabled(!BluetoothService.enabled) : ShellState.pinCard(root)
    }

    readonly property bool panelOpen: false

    function togglePanel(): void {
        ShellState.pinCard(root);
    }
}
