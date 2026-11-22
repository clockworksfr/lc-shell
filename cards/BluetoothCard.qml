import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Paired devices: name, state, battery (low battery flagged).
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var devices: BluetoothService.devices.filter(d => d.paired || d.connected)

    spacing: theme.space.s

    ThemedText {
        text: I18n.tr("bt.title")
        font.weight: Font.DemiBold
    }

    ThemedText {
        visible: !BluetoothService.enabled || root.devices.length === 0
        text: !BluetoothService.enabled ? I18n.tr("card.bluetoothOff") : I18n.tr("card.noDevices")
        color: root.theme.color.soft
    }

    Repeater {
        model: BluetoothService.enabled ? root.devices : []

        Item {
            required property var modelData
            readonly property bool low: modelData.batteryAvailable && modelData.battery < 0.2

            width: root.width
            implicitHeight: Math.max(36, names.implicitHeight)

            Column {
                id: names
                anchors.left: parent.left
                anchors.right: battery.left
                anchors.rightMargin: root.theme.space.s
                anchors.verticalCenter: parent.verticalCenter

                ThemedText {
                    width: parent.width
                    text: parent.parent.modelData.name || parent.parent.modelData.address
                    color: parent.parent.modelData.connected ? root.theme.color.ink : root.theme.color.soft
                    elide: Text.ElideRight
                }

                ThemedText {
                    text: parent.parent.modelData.connected ? I18n.tr("bt.connected") : I18n.tr("bt.paired")
                    color: root.theme.color.soft
                    font.pixelSize: root.theme.font.sizeS
                }
            }

            // Battery: small gauge and value.
            Row {
                id: battery
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: parent.modelData.batteryAvailable
                spacing: root.theme.space.xs

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36
                    height: 6
                    radius: root.theme.radius.full
                    color: root.theme.color.surface2

                    Rectangle {
                        width: parent.width * (parent.parent.parent.modelData.battery ?? 0)
                        height: parent.height
                        radius: parent.radius
                        color: parent.parent.parent.low ? root.theme.color.urgent : root.theme.color.ok
                    }
                }

                ThemedText {
                    text: I18n.percent(parent.parent.modelData.battery ?? 0)
                    color: parent.parent.low ? root.theme.color.urgent : root.theme.color.ink
                    font.pixelSize: root.theme.font.sizeS
                    font.features: ({ "tnum": 1 })
                }
            }
        }
    }
}
