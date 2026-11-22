import QtQuick
import Quickshell.Io

// qs -c lc ipc call lock <lock|preview|isLocked>
// lock: like the shortcut (the after-lock action follows);
// loginctl lock-session works too (no after-lock action).
IpcHandler {
    target: "lock"

    function lock(): void {
        Lock.lock();
    }
    // The lock screen in a window, with a real password check, nothing locked.
    function preview(): void {
        Lock.status = "";
        Lock.previewing = true;
    }
    function closePreview(): void {
        Lock.previewing = false;
    }
    function isLocked(): bool {
        return Lock.locked;
    }
}
