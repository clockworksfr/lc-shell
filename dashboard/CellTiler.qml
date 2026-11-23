pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Places windows into the window cells of their workspace's dashboard: floated, resized, moved (hl.dsp.window.* by address).
//
// - A window keeps its cell while it stays on the same workspace; new
//   windows take the first free cell; extra windows stack in the last one.
// - A window that leaves for a normal screen is put back into tiling.
// - Fullscreen windows are left alone.
Singleton {
    id: root

    // address -> { screen, workspace, cell, rect }  (rect: global, applied)
    property var managed: ({})

    function reconcile(): void {
        const next = {};
        const usedCells = {}; // "screen/workspace" -> Set of cell indices

        const windowsConfig = Dashboard.windows;
        for (const screen of Quickshell.screens) {
            if (!windowsConfig.enabled)
                continue;

            const toplevels = Hyprland.toplevels.values.filter(t => t.workspace?.monitor?.name === screen.name && (t.workspace?.id ?? 0) > 0);
            for (const toplevel of toplevels) {
                const info = toplevel.lastIpcObject ?? {};
                const windowClass = info.class ?? "";
                if (info.fullscreen)
                    continue;
                if (windowsConfig.ignore.includes(windowClass))
                    continue;
                if (windowsConfig.only.length > 0 && !windowsConfig.only.includes(windowClass))
                    continue;

                const workspace = toplevel.workspace.name;
                const preset = Dashboard.presetFor(workspace);
                const grid = Dashboard.grid(preset);
                const cells = Dashboard.cells(preset).map((cell, index) => ({ cell, index })).filter(c => c.cell.type === "window");
                if (cells.length === 0)
                    continue;

                const key = `${screen.name}/${workspace}`;
                const used = usedCells[key] ?? (usedCells[key] = new Set());
                const previous = managed[toplevel.address];

                // Keep the previous cell if still valid and free, else the first free one.
                let choice = previous && previous.screen === screen.name && previous.workspace === workspace ? cells.find(c => c.index === previous.cell && !used.has(c.index)) : null;
                choice = choice ?? cells.find(c => !used.has(c.index)) ?? cells[cells.length - 1];
                used.add(choice.index);

                const local = Dashboard.rect(choice.cell, grid, screen.width, screen.height);
                const rect = { x: screen.x + local.x, y: screen.y + local.y, width: local.width, height: local.height };
                next[toplevel.address] = { screen: screen.name, workspace: workspace, cell: choice.index, rect: rect };

                const unchanged = previous && JSON.stringify(previous.rect) === JSON.stringify(rect);
                if (!unchanged)
                    place(toplevel.address, rect);
            }
        }

        // Windows we managed that left a dashboard's window cells go back to tiling.
        for (const address in managed) {
            if (!(address in next) && Hyprland.toplevels.values.some(t => t.address === address))
                dispatch(`hl.dsp.window.float({ action = "unset", ${selector(address)} })`);
        }
        managed = next;
    }

    function selector(address: string): string {
        return `window = "address:${address.startsWith("0x") ? address : "0x" + address}"`;
    }

    function place(address: string, rect: var): void {
        const target = selector(address);
        dispatch(`hl.dsp.window.float({ action = "set", ${target} })`);
        // Resize first: it keeps the window centered; then move (global coordinates).
        dispatch(`hl.dsp.window.resize({ x = ${rect.width}, y = ${rect.height}, ${target} })`);
        dispatch(`hl.dsp.window.move({ x = ${rect.x}, y = ${rect.y}, ${target} })`);
    }

    function dispatch(command: string): void {
        Hyprland.dispatch(command);
    }

    // Window events: refresh toplevel info (class, fullscreen), then reconcile.
    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (["openwindow", "closewindow", "movewindowv2", "fullscreen", "monitoraddedv2", "monitorremovedv2", "changefloatingmode"].includes(event.name))
                refresh.restart();
        }
    }

    Connections {
        target: Config

        function onDataChanged(): void {
            refresh.restart();
        }
    }

    Timer {
        id: refresh
        interval: 80
        running: true
        onTriggered: {
            Hyprland.refreshToplevels();
            settle.restart();
        }
    }

    Timer {
        id: settle
        interval: 120
        onTriggered: root.reconcile()
    }
}
