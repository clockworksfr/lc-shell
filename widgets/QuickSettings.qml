import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.lock
import qs.panels
import qs.services

// Quick settings, for screens without the modules dashboard: network,
// Bluetooth and the active modes (caffeine, do-not-disturb) side by side,
// one click target. Click: the quick settings panel (switches, volume,
// brightness, network and Bluetooth pages). Right click: the switches.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    property bool vertical: false
    property int crossSize: 0

    // The parts, at the widget's size (S / M / L).
    readonly property var partOptions: ({ size: options.size ?? "normal" })
    readonly property real spacing: QsWindow.window?.look?.spacing ?? 18

    readonly property var contextActions: [
        ...(NetworkService.wifi ? [{ id: "wifi", icon: "wifi", text: I18n.tr("toggles.wifi"), check: "box", checked: NetworkService.wifiEnabled }] : []),
        ...(BluetoothService.available ? [{ id: "bluetooth", icon: "bluetooth", text: I18n.tr("toggles.bluetooth"), check: "box", checked: BluetoothService.enabled }] : []),
        ...(VpnService.available ? [{ id: "vpn", icon: "vpn_key", text: I18n.tr("toggles.vpn"), check: "box", checked: VpnService.active }] : []),
        { id: "dnd", icon: "do_not_disturb_on", text: I18n.tr("ctx.dnd"), check: "box", checked: NotificationCenter.dnd },
        { id: "caffeine", icon: "coffee", text: I18n.tr("toggles.caffeine"), check: "box", checked: Idle.caffeine }
    ]
    function contextAction(id: string): void {
        QuickToggles.activate(id);
    }

    implicitWidth: parts.implicitWidth
    implicitHeight: parts.implicitHeight
    width: vertical && crossSize > 0 ? crossSize : implicitWidth

    Grid {
        id: parts

        anchors.centerIn: parent
        // As many columns as parts shown (Grid keeps a hidden part's spacing).
        columns: root.vertical ? 1 : 1 + (bt.shown ? 1 : 0) + (modes.shown ? 1 : 0)
        columnSpacing: root.spacing
        rowSpacing: root.spacing / 2
        verticalItemAlignment: Grid.AlignVCenter
        horizontalItemAlignment: Grid.AlignHCenter

        Network {
            screen: root.screen
            options: root.partOptions
            vertical: root.vertical
            crossSize: root.crossSize
        }

        Bluetooth {
            id: bt
            visible: shown
            screen: root.screen
            options: root.partOptions
            vertical: root.vertical
            crossSize: root.crossSize
        }

        Modes {
            id: modes
            visible: shown
            screen: root.screen
            options: root.partOptions
            vertical: root.vertical
            crossSize: root.crossSize
        }
    }

    // Over the parts: one click target (their own panels stay closed).
    MouseArea {
        anchors.fill: parent
        z: 1
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: popup.toggle()
    }

    readonly property bool panelOpen: popup.visible

    function togglePanel(): void {
        popup.toggle();
    }

    BarPopup {
        id: popup
        anchorItem: root

        QuickSettingsPanel {}
    }
}
