import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Battery level (hidden without a battery). Click: power panel
// (time left, power profile).
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    readonly property bool shown: Power.hasBattery

    text: I18n.tr(Power.charging ? "bar.batteryCharging" : "bar.battery", { value: I18n.percent(Power.level) })
    color: Power.low ? theme.color.urgent : Power.charging ? theme.color.ok : theme.color.ink

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible = !popup.visible
    }

    BarPopup {
        id: popup
        anchorItem: root

        PowerPanel {}
    }
}
