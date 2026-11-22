pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Per-screen runtime facts: fullscreen state, where automatic popups go.
Singleton {
    id: root

    function monitor(name: string): HyprlandMonitor {
        return Hyprland.monitors.values.find(m => m.name === name) ?? null;
    }

    // A real fullscreen window (Hyprland mode 2) on the screen's active
    // workspace. A maximized window (mode 1) also sets hasFullscreen: it
    // doesn't count, the shell keeps showing over it.
    function hasFullscreen(name: string): bool {
        const workspace = monitor(name)?.activeWorkspace;
        if (!workspace?.hasFullscreen)
            return false;
        return Hyprland.toplevels.values.some(t => t.workspace === workspace && ((t.lastIpcObject?.fullscreen ?? 0) & 2));
    }

    // Where an automatic popup (OSD, notification) may appear.
    // Nothing automatic is ever drawn over a fullscreen window: the popup
    // goes to a "modules" screen instead, or nowhere ("").
    function popupTarget(preferred: string): string {
        const wanted = preferred || (Hyprland.focusedMonitor?.name ?? "");
        if (wanted && !hasFullscreen(wanted))
            return wanted;
        const fallback = Quickshell.screens.find(s => Config.forScreen(s).mode === "modules" && !hasFullscreen(s.name));
        return fallback?.name ?? "";
    }
}
