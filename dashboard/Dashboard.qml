pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Dashboards: modules laid out on a grid, shown on a workspace (whatever
// the screen), under its windows. Settings (`dashboards`):
//   grid        { cellWidth, cellHeight, gap, margin, columns?, rows? }
//               (a preset may override it). Columns and rows follow the
//               room: as many cells of about cellWidth × cellHeight as fit
//               (12 × 4 on a 2560 × 720 screen, 24 × 12 on 5120 × 2160);
//               a number fixes them.
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

    readonly property var defaultGrid: ({ cellWidth: 200, cellHeight: 165, gap: 12, margin: 12 })

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

    // The grid on a `width` × `height` area (columns and rows counted).
    function grid(preset: var, width: real, height: real): var {
        const g = Object.assign({}, defaultGrid, config.grid ?? {}, preset?.grid ?? {});
        const count = (size, cell) => Math.max(1, Math.round((size - 2 * g.margin + g.gap) / (cell + g.gap)));
        if (!(g.columns > 0))
            g.columns = count(width || 2560, g.cellWidth);
        if (!(g.rows > 0))
            g.rows = count(height || 720, g.cellHeight);
        return g;
    }

    // Monitors' reserved room (bars) is only known after a refresh; again
    // when layers come and go (a bar shown or hidden).
    Component.onCompleted: Hyprland.refreshMonitors()
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (["openlayer", "closelayer", "monitoraddedv2", "configreloaded"].includes(event.name))
                reserveRefresh.restart();
        }
    }
    Timer {
        id: reserveRefresh
        interval: 300
        onTriggered: Hyprland.refreshMonitors()
    }

    // A screen's Hyprland monitor and its active workspace, looked up in
    // the monitor list (Hyprland.monitorFor() in bindings looped on new
    // outputs and the dashboard never showed there).
    function monitorOf(screen: ShellScreen): var {
        const name = screen?.name ?? "";
        return Hyprland.monitors.values.find(m => m.name === name) ?? null;
    }
    function activeWorkspaceOn(screen: ShellScreen): string {
        return monitorOf(screen)?.activeWorkspace?.name ?? "";
    }

    // The room a dashboard has on a screen (what its bar leaves), local.
    function area(screen: ShellScreen): var {
        const r = monitorOf(screen)?.lastIpcObject?.reserved ?? [0, 0, 0, 0];
        return {
            x: r[0] ?? 0,
            y: r[1] ?? 0,
            width: (screen?.width ?? 0) - (r[0] ?? 0) - (r[2] ?? 0),
            height: (screen?.height ?? 0) - (r[1] ?? 0) - (r[3] ?? 0)
        };
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
        const ws = activeWorkspaceOn(screen);
        return !!presetNameFor(ws);
    }

    // Cell rectangle in area-local pixels. A cell past the grid (a preset
    // made on a bigger screen) is pulled back inside.
    function rect(cell: var, grid: var, width: real, height: real): var {
        const cellWidth = (width - 2 * grid.margin - (grid.columns - 1) * grid.gap) / grid.columns;
        const cellHeight = (height - 2 * grid.margin - (grid.rows - 1) * grid.gap) / grid.rows;
        const w = Math.min(cell.w ?? 1, grid.columns);
        const h = Math.min(cell.h ?? 1, grid.rows);
        const x = Math.max(0, Math.min(cell.x ?? 0, grid.columns - w));
        const y = Math.max(0, Math.min(cell.y ?? 0, grid.rows - h));
        return {
            x: Math.round(grid.margin + x * (cellWidth + grid.gap)),
            y: Math.round(grid.margin + y * (cellHeight + grid.gap)),
            width: Math.round(w * cellWidth + (w - 1) * grid.gap),
            height: Math.round(h * cellHeight + (h - 1) * grid.gap)
        };
    }
}
