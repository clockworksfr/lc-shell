pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme

// Hyprland's window borders follow the theme of the normal screens: active
// = the theme's window color (`color.windowBorder`, else `accent`: white in
// Matrix, the signal red was too loud), inactive = its line color; groups alike. Applied at start, on
// every theme / light-dark change and after each Hyprland config reload
// (which brings back the static colors of ~/.config/hypr). Off in Settings ›
// Appearance: Hyprland's own colors come back (config reload).
Singleton {
    id: root

    readonly property bool enabled: Config.get("appearance.windowBorders") ?? true
    readonly property var colors: {
        const c = Themes.resolve(Themes.themeFor("normal"), false, "normal").color;
        return {
            active: c.windowBorder ?? c.accent,
            inactive: c.windowBorderInactive ?? c.line
        };
    }

    // "#AARRGGBB" / "#RRGGBB" → Hyprland's rgba(rrggbbaa).
    function hypr(value: var): string {
        const c = Qt.color(value);
        const h = x => Math.round(x * 255).toString(16).padStart(2, "0");
        return `rgba(${h(c.r)}${h(c.g)}${h(c.b)}${h(c.a)})`;
    }

    function apply(): void {
        if (!enabled)
            return;
        const a = hypr(colors.active), i = hypr(colors.inactive);
        const lua = `hl.config({ general = { col = { active_border = "${a}", inactive_border = "${i}" } }, group = { col = { border_active = "${a}", border_inactive = "${i}" }, groupbar = { col = { active = "${a}", inactive = "${i}" } } } })`;
        run.command = ["hyprctl", "eval", lua];
        run.running = true;
    }

    onColorsChanged: debounce.restart()
    onEnabledChanged: {
        if (enabled) {
            debounce.restart();
        } else {
            run.command = ["hyprctl", "reload", "config-only"];
            run.running = true;
        }
    }
    Component.onCompleted: debounce.restart()

    Timer {
        id: debounce
        interval: 60
        onTriggered: root.apply()
    }

    Process {
        id: run
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                debounce.restart();
        }
    }
}
