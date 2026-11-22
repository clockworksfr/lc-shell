import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Big temperature, condition, feels like, wind; next 6 hours with rain
// probability; place, source and time of the reading (dated when old).
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var now: Weather.current

    spacing: theme.space.m

    ThemedText {
        visible: !Weather.enabled
        width: parent.width
        wrapMode: Text.WordWrap
        text: I18n.tr("weather.noPlace")
        color: root.theme.color.soft
    }

    Row {
        visible: !!root.now
        spacing: root.theme.space.m

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.now ? Weather.icon(root.now.code, root.now.isDay) : ""
            filled: true
            size: 44
            color: root.theme.color.accent
        }

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.now ? Weather.temp(root.now.temp) : ""
            font.family: root.theme.font.display
            font.weight: root.theme.font.displayWeight
            font.pixelSize: 44
            font.features: ({ "tnum": 1 })
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter

            ThemedText {
                text: root.now ? I18n.tr(Weather.condition(root.now.code)) : ""
                font.weight: Font.DemiBold
            }

            ThemedText {
                text: root.now ? I18n.tr("weather.feels", { value: Weather.temp(root.now.feels), wind: Math.round(root.now.wind), unit: Weather.windUnit }) : ""
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
            }
        }
    }

    // Next hours.
    Row {
        visible: Weather.hourly.length > 0
        width: parent.width

        Repeater {
            model: Weather.hourly.slice(0, 6)

            Column {
                required property var modelData
                width: parent.width / Math.max(1, Math.min(6, Weather.hourly.length))
                spacing: root.theme.space.xs

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    label: true
                    text: I18n.locale.toString(new Date(parent.modelData.time), "HH")
                    color: root.theme.color.soft
                }

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: Weather.icon(parent.modelData.code, parent.modelData.isDay)
                    size: 22
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.temp(parent.modelData.temp)
                    font.features: ({ "tnum": 1 })
                }

                ThemedText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.percent(parent.modelData.rain / 100)
                    color: parent.modelData.rain >= 50 ? root.theme.color.accent : root.theme.color.soft
                    font.pixelSize: root.theme.font.sizeS
                }
            }
        }
    }

    ThemedText {
        visible: Weather.enabled
        width: parent.width
        elide: Text.ElideRight
        text: Weather.updated > 0
            ? I18n.tr(Weather.stale ? "weather.sourceStale" : "weather.source", { place: Weather.location?.name ?? "", time: I18n.relativeTime(Weather.updated) })
            : Weather.failed ? I18n.tr("weather.offline") : I18n.tr("weather.loading")
        color: Weather.stale || Weather.failed ? root.theme.color.warn : root.theme.color.soft
        font.pixelSize: root.theme.font.sizeS
    }
}
