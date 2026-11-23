import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.dashboard
import qs.i18n
import qs.services
import qs.theme

// Dashboards as presets: which preset each workspace shows (apply one,
// none, or save the workspace's as a new preset), the presets themselves
// (new, rename, duplicate, delete). The same choices: right click on the
// background of any workspace.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var presetNames: Object.keys(Dashboard.presets).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }))
    // Workspaces that exist or have a dashboard.
    readonly property var workspaceNames: {
        const names = new Set(Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.name));
        for (const ws in Dashboard.workspaces)
            names.add(ws);
        return [...names].sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
    }

    function screenOf(ws: string): string {
        return Hyprland.workspaces.values.find(w => w.name === ws)?.monitor?.name ?? "";
    }

    spacing: theme.space.s

    Section {
        title: I18n.tr("settings.dashboardWorkspaces")

        ThemedText {
            width: parent.width
            wrapMode: Text.Wrap
            text: I18n.tr("settings.dashboardWorkspacesHint")
            color: root.theme.color.soft
            font.pixelSize: root.theme.font.sizeS
        }

        Repeater {
            model: root.workspaceNames

            Field {
                id: wsField

                required property string modelData
                readonly property string preset: Dashboard.presetNameFor(modelData)

                label: I18n.tr("settings.dashboardWorkspace", { name: modelData })
                hint: root.screenOf(modelData) || I18n.tr("settings.dashboardWorkspaceClosed")

                Row {
                    spacing: root.theme.space.s

                    Choice {
                        anchors.verticalCenter: parent.verticalCenter
                        model: [{ value: "", label: I18n.tr("settings.dashboardNone") }, ...root.presetNames.map(p => ({ value: p, label: p }))]
                        value: wsField.preset
                        onPicked: value => Dashboard.assign(wsField.modelData, value)
                    }

                    Button {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !!wsField.preset
                        icon: "content_copy"
                        text: I18n.tr("settings.dashboardSaveAs")
                        onClicked: Dashboard.saveAs(wsField.modelData, "")
                    }
                }
            }
        }

        // Another workspace (not open yet).
        Field {
            label: I18n.tr("settings.dashboardAdd")
            hint: I18n.tr("settings.dashboardAddHint")
            Choice {
                model: Array.from({ length: 10 }, (_, i) => `${i + 1}`).filter(ws => !root.workspaceNames.includes(ws)).map(ws => ({ value: ws, label: ws }))
                value: ""
                onPicked: value => Dashboard.assign(value, root.presetNames[0] ?? Dashboard.create(I18n.tr("dashEdit.workspacePreset", { name: value })))
            }
        }

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
    }

    Section {
        title: I18n.tr("settings.dashboardPresets")

        Field {
            label: I18n.tr("settings.dashboardNewPreset")
            hint: I18n.tr("settings.dashboardNewPresetHint")
            Button {
                icon: "add"
                text: I18n.tr("settings.dashboardCreate")
                onClicked: Dashboard.create(I18n.tr("settings.dashboardNewName"))
            }
        }

        Repeater {
            model: root.presetNames

            Field {
                id: presetField

                required property string modelData
                readonly property var users: Dashboard.usersOf(modelData)

                label: modelData
                hint: `${I18n.tr("settings.dashboardModules", { n: (Dashboard.presets[modelData]?.cells ?? []).length })} · ${users.length ? I18n.tr("settings.dashboardUsedBy", { list: users.join(", ") }) : I18n.tr("settings.dashboardUnused")}`

                Row {
                    spacing: root.theme.space.s

                    TextField {
                        width: 150
                        text: presetField.modelData
                        placeholder: I18n.tr("settings.dashboardRename")
                        onCommitted: text => Dashboard.rename(presetField.modelData, text)
                    }

                    Button {
                        icon: "content_copy"
                        text: I18n.tr("dashEdit.duplicate")
                        onClicked: {
                            const next = Dashboard.copy(Dashboard.presets);
                            next[Dashboard.freeName(presetField.modelData)] = Dashboard.copy(next[presetField.modelData]);
                            Config.set("dashboards.presets", next);
                        }
                    }

                    Button {
                        icon: "delete"
                        enabled: presetField.users.length === 0
                        text: I18n.tr("dashEdit.remove")
                        onClicked: Dashboard.remove(presetField.modelData)
                    }
                }
            }
        }
    }

    Section {
        title: I18n.tr("settings.dashboardOptions")

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
}
