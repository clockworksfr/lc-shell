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
