pragma Singleton

import QtQuick
import Quickshell
import qs.dashboard
import qs.i18n
import qs.settings

// The right-click menu of a workspace's background (wallpaper or the
// dashboard's empty spots): edit its modules, apply a preset or none, save
// it as a new preset, settings.
Singleton {
    function actions(workspace: string): var {
        const current = Dashboard.presetNameFor(workspace);
        const names = Object.keys(Dashboard.presets).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
        return [
            { id: "edit", icon: current ? "edit" : "add", text: I18n.tr(current ? "dashboard.menu.edit" : "dashboard.menu.add") },
            { isSeparator: true },
            ...names.map(name => ({ id: `preset:${name}`, icon: "dashboard", text: name, check: "radio", checked: name === current })),
            { id: "none", icon: "close", text: I18n.tr("dashboard.menu.none"), check: "radio", checked: !current },
            { isSeparator: true },
            ...(current ? [{ id: "saveAs", icon: "content_copy", text: I18n.tr("dashboard.menu.saveAs") }] : []),
            { id: "wallpaper", icon: "wallpaper", text: I18n.tr("dashboard.menu.wallpaper") },
            { id: "dashboard", icon: "tune", text: I18n.tr("dashboard.menu.settings") }
        ];
    }

    function pick(id: string, workspace: string, screenName: string): void {
        if (id === "edit")
            DashboardEditor.start(screenName);
        else if (id.startsWith("preset:"))
            Dashboard.assign(workspace, id.slice(7));
        else if (id === "none")
            Dashboard.assign(workspace, "");
        else if (id === "saveAs")
            Dashboard.saveAs(workspace, "");
        else if (id === "wallpaper")
            Settings.open("wallpaper");
        else if (id === "dashboard")
            Settings.open("dashboard");
    }
}
