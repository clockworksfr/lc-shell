import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Battery details and power profile choice.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    function duration(seconds: real): string {
        const minutes = Math.round(seconds / 60);
        return I18n.tr("format.duration", { h: Math.floor(minutes / 60), m: String(minutes % 60).padStart(2, "0") });
    }

    width: 320
    spacing: theme.space.s

    ListRow {
        visible: Power.hasBattery
        title: `${I18n.tr("power.battery")} ${I18n.percent(Power.level)}`
        subtitle: Power.full ? I18n.tr("power.full")
            : Power.timeLeft > 0 ? I18n.tr(Power.charging ? "power.untilFull" : "power.remaining", { time: root.duration(Power.timeLeft) })
            : Power.charging ? I18n.tr("power.charging") : ""
    }

    ThemedText {
        label: true
        text: I18n.tr("power.profile")
        color: root.theme.color.soft
    }

    Repeater {
        model: Power.profiles

        ListRow {
            required property int modelData
            title: I18n.tr(`power.profile.${Power.profileKey(modelData)}`)
            selected: Power.profile === modelData
            onClicked: Power.setProfile(modelData)
        }
    }
}
