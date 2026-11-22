import QtQuick
import Quickshell.Io

// qs -c lc ipc call dashboard <edit|done|discard>
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
}
