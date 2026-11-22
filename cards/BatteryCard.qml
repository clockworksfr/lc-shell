import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Level, state, time left, 6 h history, power profile.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    function duration(seconds: real): string {
        const minutes = Math.round(seconds / 60);
        return I18n.tr("format.duration", { h: Math.floor(minutes / 60), m: String(minutes % 60).padStart(2, "0") });
    }

    spacing: theme.space.m

    Row {
        spacing: root.theme.space.m

        ThemedText {
            text: I18n.percent(Power.level)
            font.family: root.theme.font.display
            font.weight: root.theme.font.displayWeight
            font.pixelSize: 40
            font.features: ({ "tnum": 1 })
            color: Power.low ? root.theme.color.urgent : root.theme.color.ink
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            ThemedText {
                text: Power.full ? I18n.tr("power.full") : Power.charging ? I18n.tr("power.charging") : I18n.tr("power.battery")
                font.weight: Font.DemiBold
                color: Power.charging ? root.theme.color.ok : root.theme.color.ink
            }

            ThemedText {
                visible: Power.timeLeft > 0 && !Power.full
                text: I18n.tr(Power.charging ? "power.untilFull" : "power.remaining", { time: root.duration(Power.timeLeft) })
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
            }
        }
    }

    Column {
        visible: Power.history.length >= 2
        width: parent.width
        spacing: root.theme.space.xs

        ThemedText {
            text: I18n.tr("card.history")
            label: true
            color: root.theme.color.soft
        }

        Sparkline {
            width: parent.width
            height: 48
            max: 1
            values: Power.history.map(p => p.level)
            color: Power.low ? root.theme.color.urgent : root.theme.color.ok
        }
    }

    ThemedText {
        text: I18n.tr("power.profile")
        label: true
        color: root.theme.color.soft
    }

    Choice {
        model: Power.profiles.map(p => ({ value: p, label: I18n.tr(`power.profile.${Power.profileKey(p)}`) }))
        value: Power.profile
        onPicked: value => Power.setProfile(value)
    }
}
