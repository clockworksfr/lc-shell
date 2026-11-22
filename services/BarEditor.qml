pragma Singleton

import QtQuick
import Quickshell


// Bar edit mode logic (docs/bar-editing.md).
//
// A bar's layout is three zones (left/start, center, right/end); a zone is
// a list of groups (islands), a group a list of block entries. In settings a
// zone with one group is a plain list; with several, a list of lists.
// Edits go to the screen's profile (Config.setScreen "bar"), so each screen
// has its own layout. Undo/redo keep the last 50 layouts; "discard" restores
// every screen as it was when editing started.
Singleton {
    id: root

    readonly property bool editing: ShellState.editing
    readonly property var zoneNames: ["left", "center", "right"]
    readonly property var sizes: ["compact", "normal", "extended"]

    // Selected block: { screen (name), zone, group, index } or null.
    property var selected: null
    // Drag in progress: { screen, zone, group, index, type } or null.
    property var dragging: null

    // screen name -> zones, as they were when editing started.
    property var initial: ({})
    property var undoStack: []
    property var redoStack: []

    onEditingChanged: {
        selected = null;
        dragging = null;
        if (editing) {
            const snapshot = {};
            for (const screen of Quickshell.screens)
                snapshot[screen.name] = zonesOf(screen);
            initial = snapshot;
            undoStack = [];
            redoStack = [];
        }
    }

    function screenNamed(name: string): ShellScreen {
        return Quickshell.screens.find(s => s.name === name) ?? null;
    }

    function groups(list: var): var {
        const entries = list ?? [];
        if (entries.some(e => Array.isArray(e)))
            return entries.map(e => Array.isArray(e) ? e.slice() : [e]);
        return [entries.slice()];
    }

    function flatten(groups: var): var {
        const kept = groups.filter(g => g.length > 0);
        return kept.length <= 1 ? (kept[0] ?? []) : kept;
    }

    // { left: [[entry]], center: [[…]], right: [[…]] } of a screen.
    function zonesOf(screen: ShellScreen): var {
        const bar = Config.forScreen(screen).bar ?? {};
        return {
            left: groups(bar.left ?? bar.start),
            center: groups(bar.center),
            right: groups(bar.right ?? bar.end)
        };
    }

    function copy(value: var): var {
        return JSON.parse(JSON.stringify(value));
    }

    function write(screen: ShellScreen, zones: var, record: bool): void {
        if (record) {
            undoStack = [...undoStack, { screen: screen.name, zones: zonesOf(screen) }].slice(-50);
            redoStack = [];
        }
        const current = Config.profileFor(screen).bar;
        const bar = Object.assign({}, current && typeof current === "object" ? current : {});
        delete bar.start;
        delete bar.end;
        for (const name of zoneNames)
            bar[name] = flatten(zones[name]);
        Config.setScreen(screen, "bar", bar);
    }

    function entryAt(at: var): var {
        const screen = screenNamed(at.screen);
        return screen ? zonesOf(screen)[at.zone]?.[at.group]?.[at.index] ?? null : null;
    }

    // Moves a block; `to.group === -1` opens a new group at the zone's end.
    function move(from: var, to: var): void {
        const screen = screenNamed(from.screen);
        if (!screen)
            return;
        const zones = copy(zonesOf(screen));
        const [entry] = zones[from.zone][from.group].splice(from.index, 1);
        if (entry === undefined)
            return;
        let index = to.index;
        if (to.group === -1) {
            zones[to.zone].push([entry]);
        } else {
            if (from.zone === to.zone && from.group === to.group && from.index < index)
                index -= 1;
            zones[to.zone][to.group].splice(index, 0, entry);
        }
        write(screen, zones, true);
        selected = null;
    }

    function remove(at: var): void {
        const screen = screenNamed(at.screen);
        if (!screen)
            return;
        const zones = copy(zonesOf(screen));
        zones[at.zone][at.group].splice(at.index, 1);
        write(screen, zones, true);
        selected = null;
    }

    function add(screenName: string, type: string, zone: string): void {
        const screen = screenNamed(screenName);
        if (!screen)
            return;
        const zones = copy(zonesOf(screen));
        const target = zones[zone];
        target[target.length - 1].push(type);
        write(screen, zones, true);
    }

    function sizeOf(entry: var): string {
        return typeof entry === "object" && entry !== null ? (entry.size ?? "normal") : "normal";
    }

    function setSize(at: var, size: string): void {
        const screen = screenNamed(at.screen);
        if (!screen)
            return;
        const zones = copy(zonesOf(screen));
        const entry = zones[at.zone][at.group][at.index];
        const object = typeof entry === "string" ? { type: entry } : Object.assign({}, entry);
        if (size === "normal")
            delete object.size;
        else
            object.size = size;
        // Back to the short form when nothing else is set.
        zones[at.zone][at.group][at.index] = Object.keys(object).length === 1 ? object.type : object;
        write(screen, zones, true);
    }

    function cycleSize(at: var): void {
        const current = sizes.indexOf(sizeOf(entryAt(at)));
        setSize(at, sizes[(current + 1) % sizes.length]);
    }

    function undo(): void {
        const last = undoStack[undoStack.length - 1];
        const screen = last ? screenNamed(last.screen) : null;
        if (!screen)
            return;
        undoStack = undoStack.slice(0, -1);
        redoStack = [...redoStack, { screen: last.screen, zones: zonesOf(screen) }];
        write(screen, last.zones, false);
        selected = null;
    }

    function redo(): void {
        const next = redoStack[redoStack.length - 1];
        const screen = next ? screenNamed(next.screen) : null;
        if (!screen)
            return;
        redoStack = redoStack.slice(0, -1);
        undoStack = [...undoStack, { screen: next.screen, zones: zonesOf(screen) }];
        write(screen, next.zones, false);
        selected = null;
    }

    // Leave, keeping the changes.
    function done(): void {
        ShellState.editing = false;
    }

    // Leave, restoring every screen's layout as it was.
    function discard(): void {
        for (const name in initial) {
            const screen = screenNamed(name);
            if (screen && JSON.stringify(zonesOf(screen)) !== JSON.stringify(initial[name]))
                write(screen, initial[name], false);
        }
        ShellState.editing = false;
    }
}
