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

    function hasFullscreen(name: string): bool {
        return monitor(name)?.activeWorkspace?.hasFullscreen ?? false;
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
