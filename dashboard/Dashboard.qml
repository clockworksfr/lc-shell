pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Dashboards: modules laid out on a grid, shown on a workspace (whatever
// the screen), under its windows. Settings (`dashboards`):
//   grid        { columns, rows, gap, margin }   (a preset may override it)
//   windows     { enabled, ignore: [classes], only: [classes] }
//   presets     { "<name>": { cells: [cells], grid? } }
//   workspaces  { "<workspace name>": "<preset name>" }
// A workspace without a preset has no dashboard.
//
// A cell: { "type": "<tile>", "x", "y", "w", "h", ...options } in grid
// units. "type": "window" is a window cell: windows on that workspace are
// floated into it (CellTiler).
Singleton {
    id: root

    readonly property var defaultGrid: ({ columns: 12, rows: 4, gap: 12, margin: 12 })

    readonly property var config: Config.data.dashboards ?? {}
    readonly property var presets: config.presets ?? {}
    readonly property var workspaces: config.workspaces ?? {}
    readonly property var windows: Object.assign({ enabled: true, ignore: [], only: [] }, config.windows ?? {})

    // Preset name of a workspace ("" = no dashboard there).
    function presetNameFor(workspaceName: string): string {
        const name = workspaces[workspaceName] ?? "";
        return name && presets[name] ? name : "";
    }

    function presetFor(workspaceName: string): var {
        const name = presetNameFor(workspaceName);
        return name ? presets[name] : null;
    }

    function grid(preset: var): var {
        return Object.assign({}, defaultGrid, config.grid ?? {}, preset?.grid ?? {});
    }

    function cells(preset: var): var {
        return preset?.cells ?? [];
    }

    // --- Presets and workspaces (settings, menus) ---

    function copy(value: var): var {
        return JSON.parse(JSON.stringify(value ?? {}));
    }

    // A preset name not taken yet ("base", "base 2"…).
    function freeName(base: string): string {
        let name = base;
        for (let i = 2; presets[name]; i++)
            name = `${base} ${i}`;
        return name;
    }

    // The workspace shows that preset ("" = no dashboard there).
    function assign(workspaceName: string, preset: string): void {
        const next = copy(workspaces);
        if (preset)
            next[workspaceName] = preset;
        else
            delete next[workspaceName];
        Config.set("dashboards.workspaces", next);
    }

    // Saves the workspace's dashboard as a new preset (a copy, used by the
    // workspace from now on); returns its name.
    function saveAs(workspaceName: string, base: string): string {
        const current = presetFor(workspaceName);
        const name = freeName(base || presetNameFor(workspaceName) || `Espace ${workspaceName}`);
        const next = copy(presets);
        next[name] = copy(current ?? { cells: [] });
        Config.set("dashboards.presets", next);
        assign(workspaceName, name);
        return name;
    }

    // A new, empty preset.
    function create(base: string): string {
        const name = freeName(base);
        const next = copy(presets);
        next[name] = { cells: [] };
        Config.set("dashboards.presets", next);
        return name;
    }

    function rename(name: string, to: string): void {
        to = to.trim();
        if (!to || to === name || presets[to] || !presets[name])
            return;
        const next = copy(presets);
        next[to] = next[name];
        delete next[name];
        const ws = copy(workspaces);
        for (const key in ws)
            if (ws[key] === name)
                ws[key] = to;
        Config.set("dashboards.presets", next);
        Config.set("dashboards.workspaces", ws);
    }

    function remove(name: string): void {
        const next = copy(presets);
        delete next[name];
        Config.set("dashboards.presets", next);
    }

    function usersOf(name: string): var {
        return Object.keys(workspaces).filter(ws => workspaces[ws] === name).sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
    }

    // Screens showing a dashboard right now (their active workspace has one).
    function showsDashboard(screen: ShellScreen): bool {
        const ws = Hyprland.monitorFor(screen)?.activeWorkspace?.name ?? "";
        return !!presetNameFor(ws);
    }

    // Cell rectangle in screen-local pixels.
    function rect(cell: var, grid: var, width: real, height: real): var {
        const cellWidth = (width - 2 * grid.margin - (grid.columns - 1) * grid.gap) / grid.columns;
        const cellHeight = (height - 2 * grid.margin - (grid.rows - 1) * grid.gap) / grid.rows;
        const w = cell.w ?? 1;
        const h = cell.h ?? 1;
        return {
            x: Math.round(grid.margin + (cell.x ?? 0) * (cellWidth + grid.gap)),
            y: Math.round(grid.margin + (cell.y ?? 0) * (cellHeight + grid.gap)),
            width: Math.round(w * cellWidth + (w - 1) * grid.gap),
            height: Math.round(h * cellHeight + (h - 1) * grid.gap)
        };
    }
}
