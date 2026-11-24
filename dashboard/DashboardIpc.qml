import QtQuick
import Quickshell
import Quickshell.Io

// qs -c lc ipc call dashboard <edit|done|discard|showcase|grid>
IpcHandler {
    target: "dashboard"

    // Edit a "modules" screen's dashboard ("" = the first one).
    function edit(screen: string): void {
        DashboardEditor.start(screen);
    }
    // A screen's grid: "columns×rows, cell width×height" (its room).
    function grid(screen: string): string {
        const target = Quickshell.screens.find(s => s.name === screen);
        if (!target)
            return "no such screen";
        const room = Dashboard.area(target);
        const g = Dashboard.grid(null, room.width, room.height);
        const cell = Dashboard.rect({ x: 0, y: 0, w: 1, h: 1 }, g, room.width, room.height);
        return `${g.columns}×${g.rows}, cell ${cell.width}×${cell.height}, room ${room.width}×${room.height}`;
    }
    function done(): void {
        DashboardEditor.done();
    }
    function discard(): void {
        DashboardEditor.discard();
    }
    // Showcase: one module type at every shape ("" = back to the pages).
    // Saves the dashboard as rendered by the shell (PNG per screen).
    function snapshot(path: string): void {
        Showcase.snapshotRequested(path);
    }
    // Quick-settings panel of the dashboard's Toggles module (reviews).
    function quickSettings(open: bool): void {
        Showcase.togglesPanel = open;
    }
    // Lights panel on a screen ("" closes it), without grabbing (reviews).
    function huePanel(screen: string): void {
        Showcase.huePanel = screen;
    }
    function showcase(type: string): void {
        Showcase.type = Showcase.types.includes(type) ? type : "";
    }
}
