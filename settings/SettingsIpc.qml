import QtQuick
import Quickshell.Io

// qs -c lc ipc call settings <toggle|openPage|search|showSetting|close>
IpcHandler {
    target: "settings"

    function toggle(): void {
        Settings.toggle();
    }
    // appearance | screens | bar | wallpaper | general
    function openPage(page: string): void {
        Settings.open(page);
    }
    // Fills the settings search (opens the window).
    function search(text: string): void {
        Settings.query = text;
        Settings.opened = true;
    }
    // Opens a setting's page and points the setting out (i18n key).
    function showSetting(page: string, key: string): void {
        Settings.show(page, key);
    }
    function close(): void {
        Settings.opened = false;
    }
}
