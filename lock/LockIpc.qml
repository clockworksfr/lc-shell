import QtQuick
import Quickshell.Io

// qs -c lc ipc call lock <lock|preview|isLocked|caffeine <bool>|isCaffeine>
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
    // Caffeine (quick settings): no idle lock, screen-off or sleep while on.
    function caffeine(on: bool): void {
        Idle.caffeine = on;
    }
    function isCaffeine(): bool {
        return Idle.caffeine;
    }
}
