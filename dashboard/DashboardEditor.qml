pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.i18n
import qs.services

// Dashboard edit mode (design study, "Dashboard editor"): the dashboard
// of one workspace, on the screen showing it. Presets (named layouts) are
// edited in a draft along with which preset each workspace uses; "done"
// saves both (dashboards.presets / .workspaces), "discard" drops them.
// Undo / redo keep the last 50 states.
//
// A cell: { type, x, y, w, h, ...options } in grid units; "window" cells
// take the workspace's windows (CellTiler).
Singleton {
    id: root

    property bool editing: false
    property string screenName: ""
    // The workspace whose dashboard is edited.
    property string workspace: ""
    // Preset being edited (the workspace's).
    property string page: ""
    // Draft: preset name -> cells, workspace name -> preset name.
    property var pages: ({})
    property var assignments: ({})
    // Selected cell index on the page, -1 = none.
    property int selected: -1
    property var undoStack: []
    property var redoStack: []

    readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === screenName) ?? null
    readonly property var grid: Dashboard.grid(Dashboard.presets[page] ?? null)
    readonly property var cells: pages[page] ?? []
    // Sizes a module snaps to (design study): S, M, L.
    readonly property var sizes: ({ S: { w: 2, h: 1 }, M: { w: 4, h: 2 }, L: { w: 6, h: 3 } })

    function copy(value: var): var {
        return JSON.parse(JSON.stringify(value ?? null));
    }

    function snapshot(): var {
        return { page: page, pages: copy(pages), assignments: copy(assignments) };
    }

    function restore(state: var): void {
        pages = state.pages;
        assignments = state.assignments;
        page = state.page;
        selected = -1;
    }

    // A preset name not taken yet ("base", "base 2", "base 3"…).
    function freeName(base: string): string {
        let name = base;
        for (let i = 2; pages[name]; i++)
            name = `${base} ${i}`;
        return name;
    }

    // Starts editing the dashboard of a screen's active workspace (by
    // screen name; "" = the first screen showing a dashboard, else the
    // focused one). A workspace without one gets a new, empty preset.
    function start(name: string): void {
        const target = Quickshell.screens.find(s => name ? s.name === name : Dashboard.showsDashboard(s))
            ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
            ?? Quickshell.screens[0];
        if (!target)
            return;
        screenName = target.name;
        workspace = Hyprland.monitorFor(target)?.activeWorkspace?.name ?? "";
        const draft = {};
        for (const key in Dashboard.presets)
            draft[key] = copy(Dashboard.presets[key].cells ?? []);
        pages = draft;
        assignments = copy(Dashboard.workspaces) ?? {};
        page = Dashboard.presetNameFor(workspace);
        if (!page) {
            page = freeName(I18n.tr("dashEdit.workspacePreset", { name: workspace }));
            pages = Object.assign({}, pages, { [page]: [] });
            assignments = Object.assign({}, assignments, { [workspace]: page });
        }
        selected = -1;
        undoStack = [];
        redoStack = [];
        editing = true;
    }

    // The workspace uses another preset (edited from now on).
    function usePreset(name: string): void {
        if (!pages[name] || name === page)
            return;
        undoStack = [...undoStack, snapshot()].slice(-50);
        redoStack = [];
        assignments = Object.assign({}, assignments, { [workspace]: name });
        page = name;
        selected = -1;
    }

    // A copy of the preset, used by the workspace from now on.
    function duplicate(): void {
        undoStack = [...undoStack, snapshot()].slice(-50);
        redoStack = [];
        const name = freeName(page);
        pages = Object.assign({}, pages, { [name]: copy(cells) });
        assignments = Object.assign({}, assignments, { [workspace]: name });
        page = name;
        selected = -1;
    }

    // No dashboard on this workspace any more (the preset is kept); saved
    // at once.
    function removeFromWorkspace(): void {
        const next = copy(assignments);
        delete next[workspace];
        assignments = next;
        done();
    }

    function setCells(list: var, record: bool): void {
        if (record) {
            undoStack = [...undoStack, snapshot()].slice(-50);
            redoStack = [];
        }
        pages = Object.assign({}, pages, { [page]: list });
    }

    function overlaps(a: var, b: var): bool {
        return a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h;
    }

    // Whether `rect` fits the grid without covering a cell (but `ignore`).
    function fits(rect: var, ignore: int): bool {
        if (rect.x < 0 || rect.y < 0 || rect.w < 1 || rect.h < 1 || rect.x + rect.w > grid.columns || rect.y + rect.h > grid.rows)
            return false;
        return cells.every((c, i) => i === ignore || !overlaps(rect, { x: c.x ?? 0, y: c.y ?? 0, w: c.w ?? 1, h: c.h ?? 1 }));
    }

    // First free spot for a w × h cell (top to bottom, left to right),
    // shrinking to 1 × 1 when the grid is full; null = no room.
    function freeSpot(w: int, h: int): var {
        for (let ww = w, hh = h; ww >= 1 && hh >= 1; ww > hh ? ww-- : hh--) {
            for (let y = 0; y + hh <= grid.rows; y++)
                for (let x = 0; x + ww <= grid.columns; x++)
                    if (fits({ x: x, y: y, w: ww, h: hh }, -1))
                        return { x: x, y: y, w: ww, h: hh };
        }
        return null;
    }

    function place(index: int, rect: var): bool {
        if (!fits(rect, index))
            return false;
        const list = copy(cells);
        Object.assign(list[index], { x: rect.x, y: rect.y, w: rect.w, h: rect.h });
        setCells(list, true);
        return true;
    }

    function add(type: string): void {
        const size = type === "window" ? { w: 4, h: 4 } : sizes.M;
        const spot = freeSpot(size.w, size.h);
        if (!spot)
            return;
        const list = copy(cells);
        list.push(Object.assign({ type: type }, spot));
        setCells(list, true);
        selected = list.length - 1;
    }

    function remove(index: int): void {
        const list = copy(cells);
        list.splice(index, 1);
        setCells(list, true);
        selected = -1;
    }

    // Snaps the selected cell to a size (S / M / L), where it fits.
    function resizeTo(index: int, size: string): bool {
        const c = cells[index];
        const s = sizes[size];
        if (!c || !s)
            return false;
        // Keep the corner, else slide left / up to fit.
        for (let dy = 0; dy <= s.h; dy++)
            for (let dx = 0; dx <= s.w; dx++) {
                const rect = { x: Math.max(0, Math.min((c.x ?? 0) - dx, grid.columns - s.w)), y: Math.max(0, Math.min((c.y ?? 0) - dy, grid.rows - s.h)), w: s.w, h: s.h };
                if (place(index, rect))
                    return true;
            }
        return false;
    }

    // A page for a workspace (starts as a copy of the default page).
    function undo(): void {
        if (!undoStack.length)
            return;
        const last = undoStack[undoStack.length - 1];
        undoStack = undoStack.slice(0, -1);
        redoStack = [...redoStack, snapshot()];
        restore(last);
    }

    function redo(): void {
        if (!redoStack.length)
            return;
        const last = redoStack[redoStack.length - 1];
        redoStack = redoStack.slice(0, -1);
        undoStack = [...undoStack, snapshot()];
        restore(last);
    }

    // Saves the presets (other keys of each preset, like a grid, kept) and
    // the workspaces' choices.
    function done(): void {
        const presets = {};
        for (const name in pages)
            presets[name] = Object.assign({}, Dashboard.presets[name] ?? {}, { cells: copy(pages[name]) });
        Config.set("dashboards.presets", presets);
        Config.set("dashboards.workspaces", copy(assignments));
        editing = false;
    }

    function discard(): void {
        editing = false;
    }
}
