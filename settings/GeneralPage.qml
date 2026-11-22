import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Language, notifications, dashboard windows.
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
        title: I18n.tr("notif.title")

        Field {
            label: I18n.tr("settings.notifPosition")
            Choice {
                model: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right"].map(v => ({ value: v, label: I18n.tr(`settings.position.${v}`) }))
                value: Config.get("notifications.position") ?? "top-right"
                onPicked: value => Config.set("notifications.position", value)
            }
        }

        Field {
            label: I18n.tr("notif.dnd")
            Switch {
                width: 60
                checked: NotificationCenter.dnd
                onToggled: NotificationCenter.setDnd(!checked)
            }
        }
    }

    Section {
        title: I18n.tr("settings.dashboard")

        Field {
            label: I18n.tr("settings.dashboardWindows")
            hint: I18n.tr("settings.dashboardWindowsHint")
            Switch {
                width: 60
                checked: Config.get("modes.modules.dashboard.windows.enabled") ?? true
                onToggled: Config.set("modes.modules.dashboard.windows.enabled", !checked)
            }
        }
    }
}
