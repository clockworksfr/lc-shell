import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Battery level (hidden without a battery). Click: power panel
// (time left, power profile).
TextBlock {
    id: root

    readonly property bool shown: Power.hasBattery

    fullText: I18n.tr(Power.charging ? "bar.batteryCharging" : "bar.battery", { value: I18n.percent(Power.level) })
    compactText: I18n.tr("bar.v.battery", { value: Math.round(Power.level * 100) })
    color: Power.low ? theme.color.urgent : Power.charging ? theme.color.ok : theme.color.ink

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    function togglePanel(): void {
        popup.toggle();
    }

    BarPopup {
        id: popup
        anchorItem: root

        PowerPanel {}
    }
}
