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

    fullText: size === "compact" ? I18n.percent(Power.level)
        : size === "extended" && Power.timeLeft > 0 ? `${I18n.tr(Power.charging ? "bar.batteryCharging" : "bar.battery", { value: I18n.percent(Power.level) })} · ${Math.floor(Power.timeLeft / 3600)}h${String(Math.round(Power.timeLeft / 60) % 60).padStart(2, "0")}`
        : I18n.tr(Power.charging ? "bar.batteryCharging" : "bar.battery", { value: I18n.percent(Power.level) })
    compactText: I18n.tr("bar.v.battery", { value: Math.round(Power.level * 100) })
    color: Power.low ? theme.color.urgent : Power.charging ? theme.color.ok : theme.color.ink

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

        PowerPanel {}
    }
}
