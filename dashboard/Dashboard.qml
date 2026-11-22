pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Geometry of "modules" screens (the dashboard).
//
// Config (shell.json, modes.modules.dashboard, overridable per screen):
//   grid     { columns, rows, gap, margin }
//   pages    { "default": [cells], "<workspace name>": [cells] }
//            Each Hyprland workspace of the screen is a page; a workspace
//            without its own page uses "default".
//   windows  { enabled, ignore: [classes], only: [classes] }
//
// A cell: { "type": "<tile>", "x", "y", "w", "h", ...options } in grid
// units. "type": "window" is a window cell: windows on that workspace are
// floated into it (CellTiler).
Singleton {
    id: root

    readonly property var defaultGrid: ({ columns: 12, rows: 4, gap: 12, margin: 12 })

    function configFor(screen: ShellScreen): var {
        return Config.forScreen(screen).dashboard ?? {};
    }

    function grid(config: var): var {
        return Object.assign({}, defaultGrid, config.grid ?? {});
    }

    function page(config: var, workspaceName: string): var {
        const pages = config.pages ?? {};
        return pages[workspaceName] ?? pages.default ?? [];
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
