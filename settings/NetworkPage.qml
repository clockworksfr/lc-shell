import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services
import qs.theme

// Network: Wi-Fi (networks, password of a new one), wired link, VPNs; the
// bar's traffic source and the quick settings' VPN. Scans while open.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    Component.onCompleted: {
        NetworkService.scanRequests++;
        NetworkService.watchers++;
    }
    Component.onDestruction: {
        NetworkService.scanRequests--;
        NetworkService.watchers--;
    }

    spacing: theme.space.s

    Section {
        title: I18n.tr("netset.connections")

        // Wired, VPNs, Wi-Fi switch and networks (password inline).
        NetworkPanel {
            width: parent.width
            foldAfter: 4
        }
    }

    Section {
        title: I18n.tr("netset.options")

        Field {
            label: I18n.tr("netset.source")
            hint: I18n.tr("netset.sourceHint")
            Choice {
                model: [{ value: "auto", label: I18n.tr("netset.auto") }, { value: "all", label: I18n.tr("netset.all") }, ...NetworkService.interfaces.map(i => ({ value: i.name, label: i.name }))]
                value: NetworkService.source
                onPicked: value => NetworkService.setSource(value)
            }
        }

        Field {
            visible: VpnService.connections.length > 0
            label: I18n.tr("netset.vpn")
            hint: I18n.tr("netset.vpnHint")
            Choice {
                model: VpnService.connections.map(c => ({ value: c.name, label: c.name }))
                value: VpnService.current?.name ?? ""
                onPicked: value => VpnService.choose(value)
            }
        }
    }
}
