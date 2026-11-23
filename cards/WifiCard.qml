import QtQuick
import Quickshell
import Quickshell.Networking
import qs.components
import qs.i18n
import qs.services
import qs.settings
import qs.theme

// Wi-Fi: power, the 4 strongest networks; join a known or open network in
// one click (a new secured one: Settings › Network, for its password).
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // Scanning while the card is open.
    readonly property bool scanning: (QsWindow.window?.phase ?? "") !== "" && NetworkService.wifiEnabled
    onScanningChanged: NetworkService.scanRequests += scanning ? 1 : -1
    Component.onDestruction: if (scanning) NetworkService.scanRequests -= 1

    spacing: 4

    CardParts.Header {
        title: I18n.tr("toggles.wifi")
        status: !NetworkService.wifi ? I18n.tr("net.noWifi")
            : !NetworkService.wifiEnabled ? I18n.tr("qs.off")
            : NetworkService.activeWifi ? NetworkService.activeWifi.name
            : I18n.tr("card.notConnected")
        switchShown: !!NetworkService.wifi
        checked: NetworkService.wifiEnabled
        onToggled: NetworkService.setWifiEnabled(!NetworkService.wifiEnabled)
    }

    Item {
        width: 1
        height: 4
    }

    Repeater {
        model: NetworkService.wifiEnabled ? NetworkService.wifiNetworks.slice(0, 4) : []

        CardParts.Line {
            id: net

            required property var modelData
            readonly property bool secured: NetworkService.isSecured(modelData)
            readonly property bool busy: modelData.state === ConnectionState.Connecting || modelData.state === ConnectionState.Disconnecting
            readonly property real strength: modelData.signalStrength

            icon: secured && !modelData.known && !modelData.connected ? "wifi_lock" : strength > 0.66 ? "wifi" : strength > 0.33 ? "wifi_2_bar" : "wifi_1_bar"
            title: modelData.name
            sub: `${busy ? I18n.tr("net.connecting") : modelData.connected ? I18n.tr("net.connected") : modelData.known ? I18n.tr("net.saved") : secured ? I18n.tr("net.secured") : I18n.tr("net.open")} · ${I18n.percent(strength)}`
            active: modelData.connected
            control: "button"
            buttonText: I18n.tr(modelData.connected ? "card.disconnect" : modelData.known || !secured ? "card.join" : "card.password")
            onPressed: {
                if (modelData.connected) {
                    NetworkService.disconnect(modelData);
                } else if (modelData.known || !secured) {
                    NetworkService.connect(modelData, "");
                } else {
                    ShellState.cardRequested("", "");
                    Settings.open("network");
                }
            }
        }
    }

    Item {
        width: 1
        height: 6
    }

    CardParts.Footer {
        page: "network"
        pageName: I18n.tr("net.title")
        hints: I18n.tr("card.hintsWifi")
    }
}
