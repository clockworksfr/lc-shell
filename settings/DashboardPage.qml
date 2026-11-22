import QtQuick
import Quickshell
import qs.components
import qs.dashboard
import qs.i18n
import qs.services
import qs.theme

// Dashboard of "modules" screens.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.dashboard")

        Field {
            label: I18n.tr("settings.dashboardEdit")
            hint: I18n.tr("settings.dashboardEditHint")
            Button {
                primary: true
                icon: "edit"
                enabled: Quickshell.screens.some(s => Config.forScreen(s).mode === "modules")
                text: I18n.tr("settings.dashboardEditButton")
                onClicked: {
                    Settings.opened = false;
                    DashboardEditor.start("");
                }
            }
        }

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
