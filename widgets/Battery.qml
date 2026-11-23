import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.panels
import qs.services

// Battery level (hidden without a battery). Click: power panel
// (time left, power profile).
TextWidget {
    id: root

    readonly property bool shown: Power.hasBattery

    fullText: size === "compact" ? I18n.percent(Power.level)
        : size === "extended" && Power.timeLeft > 0 ? `${I18n.tr(Power.charging ? "bar.batteryCharging" : "bar.battery", { value: I18n.percent(Power.level) })} · ${Math.floor(Power.timeLeft / 3600)}h${String(Math.round(Power.timeLeft / 60) % 60).padStart(2, "0")}`
        : I18n.tr(Power.charging ? "bar.batteryCharging" : "bar.battery", { value: I18n.percent(Power.level) })
    // Matrix: the value in ink, "↑" while charging (no green).
    compactText: I18n.tr("bar.v.battery", { value: `${Math.round(Power.level * 100)}${Power.charging && labelled ? "↑" : ""}` })
    color: Power.low ? theme.color.urgent : Power.charging && !labelled ? theme.color.ok : theme.color.ink

    icon: Power.charging ? "battery_charging_full" : Power.low ? "battery_alert" : Power.level > 0.95 ? "battery_full" : `battery_${Math.min(6, Math.floor(Power.level * 7))}_bar`
    iconFilled: true
    iconText: size === "compact" ? `${Math.round(Power.level * 100)}`
        : size === "extended" && Power.timeLeft > 0 && !vertical ? `${I18n.percent(Power.level)} · ${Math.floor(Power.timeLeft / 3600)}h${String(Math.round(Power.timeLeft / 60) % 60).padStart(2, "0")}`
        : vertical ? `${Math.round(Power.level * 100)}`
        : I18n.percent(Power.level)

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
