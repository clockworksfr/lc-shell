import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.dashboard
import qs.i18n
import qs.services
import qs.theme

// Dashboards: which workspace shows which preset, the presets (rename,
// duplicate, delete), window cells.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var presetNames: Object.keys(Dashboard.presets).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
    readonly property var assigned: Object.keys(Dashboard.workspaces).filter(ws => !!Dashboard.presets[Dashboard.workspaces[ws]]).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))

    function copy(value: var): var {
        return JSON.parse(JSON.stringify(value ?? {}));
    }

    function assign(workspace: string, preset: string): void {
        const next = copy(Dashboard.workspaces);
        if (preset)
            next[workspace] = preset;
        else
            delete next[workspace];
        Config.set("dashboards.workspaces", next);
    }

    function freeName(base: string): string {
        let name = base;
        for (let i = 2; Dashboard.presets[name]; i++)
            name = `${base} ${i}`;
        return name;
    }

    function duplicate(name: string): void {
        const presets = copy(Dashboard.presets);
        presets[freeName(name)] = copy(presets[name]);
        Config.set("dashboards.presets", presets);
    }

    function rename(name: string, to: string): void {
        to = to.trim();
        if (!to || to === name || Dashboard.presets[to])
            return;
        const presets = copy(Dashboard.presets);
        presets[to] = presets[name];
        delete presets[name];
        const workspaces = copy(Dashboard.workspaces);
        for (const ws in workspaces)
            if (workspaces[ws] === name)
                workspaces[ws] = to;
        Config.set("dashboards.presets", presets);
        Config.set("dashboards.workspaces", workspaces);
    }

    function remove(name: string): void {
        const presets = copy(Dashboard.presets);
        delete presets[name];
        Config.set("dashboards.presets", presets);
    }

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.dashboard")

        Field {
            label: I18n.tr("settings.dashboardEdit")
            hint: I18n.tr("settings.dashboardEditHint")
            Button {
                primary: true
                icon: "edit"
                text: I18n.tr("settings.dashboardEditButton")
                onClicked: {
                    Settings.opened = false;
                    DashboardEditor.start(Hyprland.focusedMonitor?.name ?? "");
                }
            }
        }

        // Workspaces with a dashboard: their preset (or none).
        Repeater {
            model: root.assigned

            Field {
                id: wsField
                required property string modelData
                label: I18n.tr("settings.dashboardWorkspace", { name: modelData })
                Choice {
                    model: [{ value: "", label: I18n.tr("settings.dashboardNone") }, ...root.presetNames.map(p => ({ value: p, label: p }))]
                    value: Dashboard.workspaces[wsField.modelData] ?? ""
                    onPicked: value => root.assign(wsField.modelData, value)
                }
            }
        }

        // A dashboard on another workspace.
        Field {
            visible: root.presetNames.length > 0
            label: I18n.tr("settings.dashboardAdd")
            hint: I18n.tr("settings.dashboardAddHint")
            Choice {
                // Workspace numbers (short: the row stays in the window).
                model: Array.from({ length: 10 }, (_, i) => `${i + 1}`).filter(ws => !root.assigned.includes(ws)).map(ws => ({ value: ws, label: ws }))
                value: ""
                onPicked: value => root.assign(value, root.presetNames[0])
            }
        }

        Field {
            label: I18n.tr("settings.dashboardWindows")
            hint: I18n.tr("settings.dashboardWindowsHint")
            Switch {
                width: 60
                checked: Dashboard.windows.enabled
                onToggled: Config.set("dashboards.windows.enabled", !checked)
            }
        }
    }

    Section {
        title: I18n.tr("settings.dashboardPresets")

        ThemedText {
            visible: root.presetNames.length === 0
            text: I18n.tr("settings.dashboardNoPreset")
            color: root.theme.color.soft
        }

        Repeater {
            model: root.presetNames

            Field {
                id: presetField

                required property string modelData
                readonly property var users: Object.keys(Dashboard.workspaces).filter(ws => Dashboard.workspaces[ws] === modelData)

                label: modelData
                hint: users.length ? I18n.tr("settings.dashboardUsedBy", { list: users.join(", ") }) : I18n.tr("settings.dashboardUnused")

                Row {
                    spacing: root.theme.space.s

                    TextField {
                        width: 160
                        text: presetField.modelData
                        placeholder: I18n.tr("settings.dashboardRename")
                        onCommitted: text => root.rename(presetField.modelData, text)
                    }

                    Button {
                        icon: "content_copy"
                        text: I18n.tr("dashEdit.duplicate")
                        onClicked: root.duplicate(presetField.modelData)
                    }

                    Button {
                        icon: "delete"
                        enabled: presetField.users.length === 0
                        text: I18n.tr("dashEdit.remove")
                        onClicked: root.remove(presetField.modelData)
                    }
                }
            }
        }
    }
}
