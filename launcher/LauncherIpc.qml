import QtQuick
import Quickshell.Io

// qs -c lc ipc call launcher <toggle|openWith|close>
IpcHandler {
    target: "launcher"

    function toggle(): void {
        Launcher.toggle();
    }
    // Open with a prefilled input, e.g. ":" for emoji, "/" for files.
    function openWith(text: string): void {
        Launcher.open(text);
    }
    function close(): void {
        Launcher.close();
    }
}
