import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Language, animations, power profile, about (config file). Lock and idle: LockPage.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.language")

        Field {
            label: I18n.tr("settings.language")
            hint: I18n.tr("settings.languageHint")
            Choice {
                model: [{ value: "auto", label: I18n.tr("settings.language.auto") }, { value: "en", label: "English" }, { value: "fr", label: "Français" }]
                value: I18n.setting
                onPicked: value => I18n.setLanguage(value)
            }
        }
    }

    Section {
        title: I18n.tr("settings.accessibility")

        Field {
            label: I18n.tr("settings.motion")
            hint: I18n.tr("settings.motionHint")
            Choice {
                model: [{ value: "system", label: I18n.tr("settings.motion.system") }, { value: "full", label: I18n.tr("settings.motion.full") }, { value: "reduced", label: I18n.tr("settings.motion.reduced") }]
                value: { const v = Config.get("appearance.reducedMotion"); return v === true ? "reduced" : v === false ? "full" : "system"; }
                onPicked: value => Config.set("appearance.reducedMotion", value === "reduced" ? true : value === "full" ? false : undefined)
            }
        }
    }

    Section {
        visible: PowerProfiles.profile !== undefined
        title: I18n.tr("settings.powerTitle")

        Field {
            label: I18n.tr("settings.powerProfile")
            Choice {
                model: Power.profiles.map(p => ({ value: p, label: I18n.tr(`power.profile.${Power.profileKey(p)}`) }))
                value: Power.profile
                onPicked: value => Power.setProfile(value)
            }
        }
    }

    Section {
        title: I18n.tr("settings.about")

        Field {
            label: I18n.tr("settings.configFile")
            hint: Config.userPath
            Row {
                spacing: root.theme.space.s

                Button {
                    icon: "folder_open"
                    text: I18n.tr("settings.open")
                    onClicked: Quickshell.execDetached(["xdg-open", Config.userPath])
                }

                Button {
                    icon: "restart_alt"
                    text: I18n.tr("settings.reload")
                    onClicked: Quickshell.reload(true)
                }
            }
        }
    }
}
