import QtQuick
import Quickshell.Io

// qs -c lc ipc call settings <toggle|openPage|close>
IpcHandler {
    target: "settings"

    function toggle(): void {
        Settings.toggle();
    }
    // appearance | screens | bar | wallpaper | general
    function openPage(page: string): void {
        Settings.open(page);
    }
    function close(): void {
        Settings.opened = false;
    }
}
