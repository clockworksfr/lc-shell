import QtQuick
import Quickshell.Io

// qs -c lc ipc call dashboard <edit|done|discard|showcase>
IpcHandler {
    target: "dashboard"

    // Edit a "modules" screen's dashboard ("" = the first one).
    function edit(screen: string): void {
        DashboardEditor.start(screen);
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
