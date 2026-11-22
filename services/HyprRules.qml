pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Hyprland layer rules for the shell's own surfaces, applied at start and
// after every config reload (which drops runtime rules):
// - no compositor animation on drawers (cards, panels) and the screenshot
//   editor: they animate themselves, and the compositor's map / resize
//   animation stretched them as they opened.
Singleton {
    id: root

    readonly property var noAnim: ["lc-card", "lc-panel", "lc-screenshot"]
    property bool applied: false

    function apply(): void {
        const lua = `hl.layer_rule({ name = "lc-shell-no-anim", match = { namespace = "^(${noAnim.join("|")})$" }, no_anim = true })`;
        run.command = ["hyprctl", "eval", lua];
        run.running = true;
    }

    Component.onCompleted: later.restart()

    Timer {
        id: later
        interval: 100
        onTriggered: root.apply()
    }

    Process {
        id: run
        stdout: StdioCollector {
            onStreamFinished: {
                root.applied = text.trim() === "ok";
                if (!root.applied)
                    console.warn(`HyprRules: ${text.trim()}`);
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                later.restart();
        }
    }
}
