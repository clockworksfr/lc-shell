import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Network status. Click: network panel (Wi-Fi list, wired state).
TextBlock {
    id: root

    readonly property string signal: NetworkService.activeWifi ? I18n.percent(NetworkService.activeWifi.signalStrength) : ""

    fullText: size === "compact" ? compactText.replace("\n", " ")
        : NetworkService.kind === "wired" ? I18n.tr("net.wired")
        : NetworkService.kind === "wifi" ? `${NetworkService.activeWifi.name} ${signal}`
        : I18n.tr("net.offline")
    compactText: NetworkService.kind === "wired" ? I18n.tr("bar.v.wired")
        : NetworkService.kind === "wifi" ? I18n.tr("bar.v.wifi", { value: signal })
        : I18n.tr("bar.v.offline")
    color: NetworkService.kind === "none" ? theme.color.soft : theme.color.ink

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
        onVisibleChanged: NetworkService.scanRequests += visible ? 1 : -1

        NetworkPanel {}
    }
}
