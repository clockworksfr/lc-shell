import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Network status. Click: network panel (Wi-Fi list, wired state).
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    text: NetworkService.kind === "wired" ? I18n.tr("net.wired")
        : NetworkService.kind === "wifi" ? `${NetworkService.activeWifi.name} ${I18n.percent(NetworkService.activeWifi.signalStrength)}`
        : I18n.tr("net.offline")
    color: NetworkService.kind === "none" ? theme.color.soft : theme.color.ink

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible = !popup.visible
    }

    BarPopup {
        id: popup
        anchorItem: root
        onVisibleChanged: NetworkService.scanRequests += visible ? 1 : -1

        NetworkPanel {}
    }
}
