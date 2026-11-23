pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Runtime state shared across screens (not persisted).
Singleton {
    property bool barVisible: true

    // Bar edit mode (every bar): drag blocks, sizes, palette (BarEditor).
    property bool editing: false

    // Ask the bar block of `type` on screen `screenName` (focused screen if
    // empty) to toggle its panel: keyboard binds, scripts, reviews.
    signal panelRequested(string type, string screenName)

    // Bar blocks currently shown (WidgetSlot items), for diagnostics/IPC.
    property var slots: []
    // Hover card state: { visible, type, screen }.
    property var card: ({ visible: false })

    // Show (type) or hide ("") the hover card of a block without hovering:
    // reviews, screenshots. On `screenName`, or the focused screen.
    signal cardRequested(string type, string screenName)
    // Reviews: where the bar and its open card are on their screen
    // ("bar x,y wxh" / "card x,y wxh", screen coordinates), to crop them.
    property var barGeometry: ({})
    // A widget's click: its hover card pinned open (or unpinned).
    signal cardPinRequested(var widget)
    function pinCard(widget: var): void {
        cardPinRequested(widget);
    }

    // Open a bar menu without a right click (key binds, reviews): "bar"
    // (the bar's menu) or "tray:N" (the menu of the Nth tray item), on
    // `screenName` or the focused screen.
    signal menuRequested(string menu, string screenName)

    function addSlot(slot: var): void {
        slots = [...slots, slot];
    }

    function removeSlot(slot: var): void {
        slots = slots.filter(s => s !== slot);
    }

    // After a panel that took the keyboard closes (quick settings, lights,
    // color): give the keyboard back to Hyprland's active window. Touching
    // the dashboard (a layer surface) leaves no window focused otherwise,
    // and typing went nowhere until a workspace switch.
    function restoreFocus(): void {
        refocus.running = false;
        refocus.running = true;
    }

    Process {
        id: refocus
        // Without moving the pointer (cursor:no_warps for the time of it).
        command: ["sh", "-c", `
            a=$(hyprctl activewindow -j | jq -r '.address // empty')
            [ -n "$a" ] || exit 0
            w=$(hyprctl getoption cursor:no_warps -j | jq -r '.bool')
            hyprctl eval 'hl.config({ cursor = { no_warps = true } })' >/dev/null
            hyprctl dispatch "hl.dsp.focus({ window = 'address:$a' })" >/dev/null
            [ "$w" = true ] || hyprctl eval 'hl.config({ cursor = { no_warps = false } })' >/dev/null`]
    }
}
