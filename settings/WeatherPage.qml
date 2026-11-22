import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Weather: place (never guessed; searched on open-meteo), units, on/off.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.s

    Section {
        title: I18n.tr("weather.title")

        Field {
            label: I18n.tr("weather.place")
            hint: Weather.location ? I18n.tr("weather.placeHint", { place: Weather.location.name }) : I18n.tr("weather.placeNone")
            TextField {
                width: 260
                placeholder: I18n.tr("weather.searchPlace")
                onCommitted: text => Weather.search(text)
            }
        }

        // Search results: pick one (it's the only time the place is sent).
        Column {
            visible: Weather.results.length > 0
            width: parent.width
            spacing: 2

            Repeater {
                model: Weather.results

                ListRow {
                    required property var modelData
                    width: parent.width
                    title: modelData.name
                    subtitle: [modelData.region, modelData.country].filter(s => !!s).join(", ")
                    onClicked: Weather.choose(modelData)
                }
            }
        }

        Field {
            label: I18n.tr("weather.units")
            Choice {
                model: [{ value: "metric", label: "°C · km/h" }, { value: "imperial", label: "°F · mph" }]
                value: Config.get("weather.units") ?? "metric"
                onPicked: value => Config.set("weather.units", value)
            }
        }

        Field {
            visible: !!Weather.location
            label: I18n.tr("weather.enabled")
            Switch {
                width: 60
                checked: Config.get("weather.enabled") ?? true
                onToggled: Config.set("weather.enabled", !checked)
            }
        }
    }
}
