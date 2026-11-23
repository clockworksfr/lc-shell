import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Connection, live download/upload with a 60 s curve, local address.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Component.onCompleted: NetworkService.watchers++
    Component.onDestruction: NetworkService.watchers--

    spacing: theme.space.s

    CardParts.Header {
        title: NetworkService.kind === "wired" ? I18n.tr("net.wired") : NetworkService.kind === "wifi" ? NetworkService.activeWifi.name : I18n.tr("net.offline")
        status: [NetworkService.address, NetworkService.kind === "wifi" ? I18n.percent(NetworkService.activeWifi.signalStrength) : NetworkService.kind === "wired" && NetworkService.wired?.linkSpeed ? `${NetworkService.wired.linkSpeed} Mb/s` : "", VpnService.active || VpnService.activeNames.length > 0 ? "VPN" : ""].filter(t => !!t).join(" · ")
        switchShown: false
    }

    Row {
        visible: NetworkService.kind !== "none"
        width: parent.width
        spacing: root.theme.space.s

        Repeater {
            model: [
                { label: I18n.tr("card.download"), glyph: "↓", rate: NetworkService.rxRate, history: NetworkService.rxHistory, color: root.theme.color.accent },
                { label: I18n.tr("card.upload"), glyph: "↑", rate: NetworkService.txRate, history: NetworkService.txHistory, color: root.theme.color.accent2 }
            ]

            Rectangle {
                required property var modelData

                width: (root.width - root.theme.space.s) / 2
                implicitHeight: tile.implicitHeight + root.theme.space.m * 2
                radius: root.theme.radius.tile
                color: root.theme.color.surface2

                Column {
                    id: tile

                    anchors.fill: parent
                    anchors.margins: root.theme.space.m
                    spacing: root.theme.space.xs

                    ThemedText {
                        text: `${parent.parent.modelData.glyph} ${parent.parent.modelData.label}`
                        label: true
                        color: root.theme.color.soft
                    }

                    ThemedText {
                        text: I18n.bytes(parent.parent.modelData.rate, true)
                        font.weight: Font.DemiBold
                        font.features: ({ "tnum": 1 })
                    }

                    Sparkline {
                        width: parent.width
                        height: 32
                        values: parent.parent.modelData.history
                        color: parent.parent.modelData.color
                    }
                }
            }
        }
    }

    // Wired link.
    CardParts.Line {
        visible: !!NetworkService.wired
        icon: "lan"
        title: I18n.tr("net.wired")
        sub: NetworkService.wiredConnected ? [I18n.tr("net.connected"), NetworkService.wired?.linkSpeed ? `${NetworkService.wired.linkSpeed} Mb/s` : ""].filter(t => !!t).join(" · ") : I18n.tr("net.disconnected")
        active: NetworkService.wiredConnected
        control: "text"
        trailing: NetworkService.source === "auto" ? "" : NetworkService.source
    }

    // VPNs: a switch each.
    Repeater {
        model: VpnService.connections

        CardParts.Line {
            required property var modelData

            icon: modelData.active ? "vpn_lock" : "vpn_key"
            title: modelData.name
            sub: (modelData.active ? I18n.tr("net.connected") : I18n.tr("net.disconnected")) + (VpnService.current?.name === modelData.name ? ` · ${I18n.tr("net.vpnDefault")}` : "")
            active: modelData.active
            control: "switch"
            checked: modelData.active
            onToggled: {
                VpnService.choose(modelData.name);
                VpnService.setActive(modelData, !modelData.active);
            }
        }
    }

    Item {
        width: 1
        height: 2
    }

    CardParts.Footer {
        page: "network"
        pageName: I18n.tr("net.title")
    }
}
