import QtQuick
import Quickshell
import Quickshell.Networking
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Wired state, Wi-Fi switch and networks. Click a network to connect or
// disconnect; secured unknown networks ask for the passphrase inline.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    // Network waiting for its passphrase.
    property var pskTarget: null
    // > 0: only that many networks (connected and known first), the others
    // under an "Other networks (n)" line.
    property int foldAfter: 0
    property bool unfolded: false
    readonly property var networks: NetworkService.wifiEnabled ? NetworkService.wifiNetworks.slice().sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)).slice(0, 24) : []
    readonly property var shownNetworks: foldAfter > 0 && !unfolded ? networks.slice(0, foldAfter) : networks

    width: 360
    spacing: theme.space.s

    ListRow {
        visible: !!NetworkService.wired
        title: I18n.tr("net.wired")
        subtitle: NetworkService.wiredConnected ? I18n.tr("net.connected") : I18n.tr("net.disconnected")
        selected: NetworkService.wiredConnected
        trailing: NetworkService.wired?.linkSpeed ? `${NetworkService.wired.linkSpeed} Mb/s` : ""
    }

    // VPNs: a click connects or disconnects one (and makes it the quick
    // settings' VPN).
    ThemedText {
        visible: VpnService.connections.length > 0
        text: I18n.tr("net.vpn")
        label: true
        color: root.theme.color.soft
        topPadding: root.theme.space.xs
    }

    Repeater {
        model: VpnService.connections

        ListRow {
            required property var modelData
            title: modelData.name
            subtitle: (modelData.active ? I18n.tr("net.connected") : I18n.tr("net.disconnected")) + (VpnService.current?.name === modelData.name ? ` · ${I18n.tr("net.vpnDefault")}` : "")
            selected: modelData.active
            onClicked: {
                VpnService.choose(modelData.name);
                VpnService.setActive(modelData, !modelData.active);
            }
        }
    }

    Switch {
        visible: !!NetworkService.wifi
        text: I18n.tr("net.wifi")
        checked: NetworkService.wifiEnabled
        onToggled: NetworkService.setWifiEnabled(!checked)
    }

    ThemedText {
        visible: !NetworkService.wifi
        text: I18n.tr("net.noWifi")
        color: root.theme.color.soft
    }

    Repeater {
        model: root.shownNetworks

        Column {
            id: entry

            required property var modelData
            readonly property bool secured: NetworkService.isSecured(modelData)
            readonly property bool busy: modelData.state === ConnectionState.Connecting || modelData.state === ConnectionState.Disconnecting

            width: root.width

            ListRow {
                title: entry.modelData.name
                subtitle: entry.busy ? I18n.tr("net.connecting")
                    : entry.modelData.connected ? I18n.tr("net.connected")
                    : entry.modelData.known ? I18n.tr("net.saved")
                    : entry.secured ? I18n.tr("net.secured") : I18n.tr("net.open")
                trailing: I18n.percent(entry.modelData.signalStrength)
                selected: entry.modelData.connected
                onClicked: {
                    const network = entry.modelData;
                    if (network.connected)
                        NetworkService.disconnect(network);
                    else if (network.known || !entry.secured)
                        NetworkService.connect(network, "");
                    else
                        root.pskTarget = root.pskTarget === network ? null : network;
                }
            }

            // Passphrase for a new secured network.
            Rectangle {
                visible: root.pskTarget === entry.modelData
                width: parent.width
                height: visible ? Math.max(root.theme.hit, psk.implicitHeight + root.theme.space.s * 2) : 0
                radius: root.theme.radius.control
                color: root.theme.color.surface2
                border.width: 1
                border.color: root.theme.color.line

                TextInput {
                    id: psk

                    anchors.fill: parent
                    anchors.margins: root.theme.space.s
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: root.theme.color.ink
                    font.family: root.theme.font.family
                    font.pixelSize: root.theme.font.sizeM
                    focus: visible
                    onVisibleChanged: if (visible) forceActiveFocus()
                    onAccepted: {
                        NetworkService.connect(entry.modelData, text);
                        text = "";
                        root.pskTarget = null;
                    }
                    Keys.onEscapePressed: root.pskTarget = null

                    ThemedText {
                        visible: !psk.text
                        text: I18n.tr("net.password")
                        color: root.theme.color.soft
                    }
                }
            }
        }
    }

    ListRow {
        visible: root.foldAfter > 0 && root.networks.length > root.foldAfter
        title: I18n.tr(root.unfolded ? "card.lessDevices" : "net.otherNetworks", { n: root.networks.length - root.foldAfter })
        trailing: root.unfolded ? "⌃" : "›"
        onClicked: root.unfolded = !root.unfolded
    }
}
