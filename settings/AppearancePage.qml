import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Themes per screen mode, light/dark and its schedule.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var themeChoices: Object.keys(Themes.definitions).map(id => ({ value: id, label: I18n.tr(`theme.${id}`) }))
    readonly property var schedule: Config.appearance.schedule ?? {}

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.themes")

        Field {
            label: I18n.tr("settings.themeNormal")
            hint: I18n.tr("settings.themeNormalHint")
            Choice {
                model: root.themeChoices
                value: Themes.themeFor("normal")
                onPicked: value => Themes.setTheme("normal", value)
            }
        }

        Field {
            label: I18n.tr("settings.themeModules")
            hint: I18n.tr("settings.themeModulesHint")
            Choice {
                model: root.themeChoices
                value: Themes.themeFor("modules")
                onPicked: value => Themes.setTheme("modules", value)
            }
        }
    }

    Section {
        title: I18n.tr("settings.appIcons")

        Field {
            label: I18n.tr("settings.appIcons")
            hint: I18n.tr("settings.appIconsHint")
            Choice {
                model: [{ value: "", label: I18n.tr("settings.ofTheme") }, ...["native", "tinted", "mono"].map(v => ({ value: v, label: I18n.tr(`settings.appIcons.${v}`) }))]
                value: Config.get("appearance.appIcons") ?? ""
                onPicked: value => Config.set("appearance.appIcons", value || undefined)
            }
        }

        Field {
            label: I18n.tr("settings.appIconTint")
            hint: I18n.tr("settings.appIconTintHint")
            Slider {
                width: 220
                from: 0.2
                to: 1
                value: Config.get("appearance.appIconTint") ?? 0.6
                onMoved: value => Config.set("appearance.appIconTint", Math.round(value * 100) / 100)
            }
        }

        Field {
            label: I18n.tr("settings.appIconContrast")
            hint: I18n.tr("settings.appIconContrastHint")
            Slider {
                width: 220
                from: 0.1
                to: 0.8
                value: Config.get("appearance.appIconContrast") ?? 0.35
                onMoved: value => Config.set("appearance.appIconContrast", Math.round(value * 100) / 100)
            }
        }

        Field {
            label: I18n.tr("settings.appIconGuard")
            hint: I18n.tr("settings.appIconGuardHint")
            Switch {
                checked: Config.get("appearance.appIconGuard") ?? true
                onToggled: Config.set("appearance.appIconGuard", !checked)
            }
        }
    }

    Section {
        title: I18n.tr("settings.variant")

        Field {
            label: I18n.tr("settings.variant")
            hint: I18n.tr("settings.variantNow", { variant: I18n.tr(`settings.variant.${Themes.variant}`) })
            Choice {
                model: ["dark", "light", "auto"].map(v => ({ value: v, label: I18n.tr(`settings.variant.${v}`) }))
                value: Themes.variantMode
                onPicked: value => Themes.setVariant(value)
            }
        }

        // 24 h strip: light and dark ranges of the schedule, now marked.
        Item {
            id: strip

            readonly property bool sun: root.schedule.type === "sun"
            readonly property var sunTimes: sun && root.schedule.latitude !== undefined ? Sun.times(new Date(), root.schedule.latitude, root.schedule.longitude ?? 0) : null
            function minutes(text: string): int {
                const m = /^(\d{1,2}):(\d{2})$/.exec(text ?? "");
                return m ? parseInt(m[1]) * 60 + parseInt(m[2]) : -1;
            }
            readonly property int lightAt: sun ? (sunTimes?.sunrise ? sunTimes.sunrise.getHours() * 60 + sunTimes.sunrise.getMinutes() : (sunTimes?.polar === "day" ? 0 : -1)) : minutes(root.schedule.light ?? "07:30")
            readonly property int darkAt: sun ? (sunTimes?.sunset ? sunTimes.sunset.getHours() * 60 + sunTimes.sunset.getMinutes() : (sunTimes?.polar === "day" ? 1440 : -1)) : minutes(root.schedule.dark ?? "19:30")

            visible: Themes.variantMode === "auto" && lightAt >= 0 && darkAt >= 0
            width: parent.width
            height: 46

            Rectangle {
                id: bar

                width: parent.width
                height: 18
                radius: 9
                color: "#20232b"
                clip: true

                // Light range (may wrap past midnight).
                Repeater {
                    model: strip.lightAt <= strip.darkAt ? [[strip.lightAt, strip.darkAt]] : [[strip.lightAt, 1440], [0, strip.darkAt]]

                    Rectangle {
                        required property var modelData
                        x: bar.width * modelData[0] / 1440
                        width: bar.width * (modelData[1] - modelData[0]) / 1440
                        height: bar.height
                        color: "#f3efe4"
                    }
                }

                // Now.
                Rectangle {
                    readonly property date now: clock.date
                    x: bar.width * (now.getHours() * 60 + now.getMinutes()) / 1440 - 1
                    width: 2
                    height: bar.height
                    color: root.theme.color.accent
                }
            }

            Repeater {
                model: [0, 6, 12, 18, 24]

                ThemedText {
                    required property int modelData
                    x: Math.max(0, Math.min(strip.width - width, strip.width * modelData / 24 - width / 2))
                    y: bar.height + 4
                    text: `${String(modelData).padStart(2, "0")}h`
                    color: root.theme.color.soft
                    font.pixelSize: root.theme.font.sizeS
                }
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }
        }

        Field {
            visible: Themes.variantMode === "auto"
            label: I18n.tr("settings.schedule")
            Choice {
                model: [{ value: "time", label: I18n.tr("settings.schedule.time") }, { value: "sun", label: I18n.tr("settings.schedule.sun") }]
                value: root.schedule.type ?? "time"
                onPicked: value => Config.set("appearance.schedule.type", value)
            }
        }

        Field {
            visible: Themes.variantMode === "auto" && (root.schedule.type ?? "time") === "time"
            label: I18n.tr("settings.lightFrom")
            TextField {
                implicitWidth: 100
                text: root.schedule.light ?? "07:30"
                placeholder: "07:30"
                onCommitted: text => /^\d{1,2}:\d{2}$/.test(text) && Config.set("appearance.schedule.light", text)
            }
        }

        Field {
            visible: Themes.variantMode === "auto" && (root.schedule.type ?? "time") === "time"
            label: I18n.tr("settings.darkFrom")
            TextField {
                implicitWidth: 100
                text: root.schedule.dark ?? "19:30"
                placeholder: "19:30"
                onCommitted: text => /^\d{1,2}:\d{2}$/.test(text) && Config.set("appearance.schedule.dark", text)
            }
        }

        Field {
            visible: Themes.variantMode === "auto" && root.schedule.type === "sun"
            label: I18n.tr("settings.latitude")
            hint: I18n.tr("settings.sunHint")
            TextField {
                implicitWidth: 120
                text: root.schedule.latitude !== undefined ? `${root.schedule.latitude}` : ""
                placeholder: "48.85"
                onCommitted: text => !isNaN(parseFloat(text)) && Config.set("appearance.schedule.latitude", parseFloat(text))
            }
        }

        Field {
            visible: Themes.variantMode === "auto" && root.schedule.type === "sun" && !!Weather.location
            label: I18n.tr("settings.sunFromWeather")
            hint: Weather.location?.name ?? ""
            Button {
                icon: "pin_drop"
                text: I18n.tr("settings.useWeatherPlace")
                onClicked: {
                    Config.set("appearance.schedule.latitude", Math.round(Weather.location.latitude * 100) / 100);
                    Config.set("appearance.schedule.longitude", Math.round(Weather.location.longitude * 100) / 100);
                }
            }
        }

        Field {
            visible: Themes.variantMode === "auto" && root.schedule.type === "sun"
            label: I18n.tr("settings.longitude")
            TextField {
                implicitWidth: 120
                text: root.schedule.longitude !== undefined ? `${root.schedule.longitude}` : ""
                placeholder: "2.35"
                onCommitted: text => !isNaN(parseFloat(text)) && Config.set("appearance.schedule.longitude", parseFloat(text))
            }
        }
    }
}
