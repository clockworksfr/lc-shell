pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Dashboard edit mode (design study, "Dashboard editor"): one "modules"
// screen at a time. Its pages (default + one per workspace) are edited in
// a draft; "done" saves them to the screen's profile (dashboard.pages),
// "discard" drops them. Undo / redo keep the last 50 states.
//
// A cell: { type, x, y, w, h, ...options } in grid units; "window" cells
// take the workspace's windows (CellTiler).
Singleton {
    id: root

    property bool editing: false
    property string screenName: ""
    // Page being edited: "default" or a workspace name.
    property string page: "default"
    // page name -> cells (draft).
    property var pages: ({})
    // Selected cell index on the page, -1 = none.
    property int selected: -1
    property var undoStack: []
    property var redoStack: []

    readonly property ShellScreen screen: Quickshell.screens.find(s => s.name === screenName) ?? null
    readonly property var config: screen ? (Config.forScreen(screen).dashboard ?? {}) : ({})
    readonly property var grid: Dashboard.grid(config)
    readonly property var cells: pages[page] ?? pages.default ?? []
    // Sizes a module snaps to (design study): S, M, L.
    readonly property var sizes: ({ S: { w: 2, h: 1 }, M: { w: 4, h: 2 }, L: { w: 6, h: 3 } })

    function copy(value: var): var {
        return JSON.parse(JSON.stringify(value ?? null));
    }

    // Starts editing a screen (by name; "" = the first "modules" screen),
    // on the page of its active workspace.
    function start(name: string): void {
        const target = Quickshell.screens.find(s => name ? s.name === name : Config.forScreen(s).mode === "modules");
        if (!target || Config.forScreen(target).mode !== "modules")
            return;
        screenName = target.name;
        pages = copy(Config.forScreen(target).dashboard?.pages ?? { default: [] });
        if (!pages.default)
            pages = Object.assign({ default: [] }, pages);
        const workspace = Hyprland.monitorFor(target)?.activeWorkspace?.name ?? "";
        page = pages[workspace] ? workspace : "default";
        selected = -1;
        undoStack = [];
        redoStack = [];
        editing = true;
    }

    function setCells(list: var, record: bool): void {
        if (record) {
            undoStack = [...undoStack, { page: page, pages: copy(pages) }].slice(-50);
            redoStack = [];
        }
        const next = copy(pages);
        next[page] = list;
        pages = next;
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
    function addPage(name: string): void {
        if (!name || pages[name])
            return;
        undoStack = [...undoStack, { page: page, pages: copy(pages) }].slice(-50);
        redoStack = [];
        const next = copy(pages);
        next[name] = copy(pages.default ?? []);
        pages = next;
        page = name;
        selected = -1;
    }

    function removePage(name: string): void {
        if (name === "default" || !pages[name])
            return;
        undoStack = [...undoStack, { page: page, pages: copy(pages) }].slice(-50);
        redoStack = [];
        const next = copy(pages);
        delete next[name];
        pages = next;
        page = "default";
        selected = -1;
    }

    function undo(): void {
        const last = undoStack[undoStack.length - 1];
        if (!last)
            return;
        redoStack = [...redoStack, { page: page, pages: copy(pages) }];
        undoStack = undoStack.slice(0, -1);
        pages = last.pages;
        page = pages[last.page] ? last.page : "default";
        selected = -1;
    }

    function redo(): void {
        const last = redoStack[redoStack.length - 1];
        if (!last)
            return;
        undoStack = [...undoStack, { page: page, pages: copy(pages) }];
        redoStack = redoStack.slice(0, -1);
        pages = last.pages;
        page = pages[last.page] ? last.page : "default";
        selected = -1;
    }

    // Saves the pages to the screen's profile (left out when equal to the
    // mode's default: later default changes still apply).
    function done(): void {
        if (screen) {
            const current = Config.profileFor(screen).dashboard;
            const dashboard = Object.assign({}, current && typeof current === "object" ? current : {});
            const defaults = Config.get("modes.modules.dashboard.pages") ?? {};
            if (JSON.stringify(pages) === JSON.stringify(defaults))
                delete dashboard.pages;
            else
                dashboard.pages = copy(pages);
            Config.setScreen(screen, "dashboard", Object.keys(dashboard).length ? dashboard : undefined);
        }
        editing = false;
    }

    function discard(): void {
        editing = false;
    }
}
