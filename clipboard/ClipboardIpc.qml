import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

// qs -c lc ipc call clipboard <toggle|open|close|pause|resume|togglePause|
//   isPaused|clear|clearAll|copy|paste|count|list>
IpcHandler {
    target: "clipboard"

    function toggle(): void {
        Clipboard.toggle();
    }
    function open(): void {
        Clipboard.open();
    }
    function close(): void {
        Clipboard.close();
    }
    // Incognito: nothing is recorded until resumed.
    function pause(): void {
        Clipboard.setPaused(true);
    }
    function resume(): void {
        Clipboard.setPaused(false);
    }
    function togglePause(): void {
        Clipboard.setPaused(!Clipboard.paused);
    }
    function isPaused(): bool {
        return Clipboard.paused;
    }
    // History only (pinned and tagged items stay) / everything.
    function clear(): void {
        Clipboard.clear(false);
    }
    function clearAll(): void {
        Clipboard.clear(true);
    }
    // Copies the n-th item (1 = newest) back to the clipboard.
    function copy(n: int): void {
        const entry = Clipboard.items[n - 1];
        if (entry)
            Clipboard.copy(entry.id, false, false);
    }
    // Copies it and pastes it into the focused window.
    function paste(n: int): void {
        const entry = Clipboard.items[n - 1];
        if (!entry)
            return;
        Clipboard.targetAddress = Hyprland.activeToplevel?.address ?? "";
        Clipboard.targetClass = Hyprland.activeToplevel?.lastIpcObject?.class ?? "";
        Clipboard.copy(entry.id, false, true);
    }
    function count(): int {
        return Clipboard.count;
    }
    // One line per item, newest first: "id kind pinned tags app" (no content).
    function list(): string {
        return Clipboard.items.map(i => `${i.id.slice(0, 10)} ${i.kind} ${i.pinned ? "pinned" : "-"} ${(i.tags ?? []).map(t => Clipboard.tag(t)?.name ?? t).join(",") || "-"} ${i.app || "-"}`).join("\n");
    }
}
