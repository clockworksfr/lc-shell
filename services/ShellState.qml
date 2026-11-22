pragma Singleton

import QtQuick
import Quickshell

// Runtime state shared across screens (not persisted).
Singleton {
    property bool barVisible: true

    // Bar edit mode (every bar): drag blocks, sizes, palette (BarEditor).
    property bool editing: false

    // Ask the bar block of `type` on screen `screenName` (focused screen if
    // empty) to toggle its panel: keyboard binds, scripts, reviews.
    signal panelRequested(string type, string screenName)

    // Bar blocks currently shown (BlockSlot items), for diagnostics/IPC.
    property var slots: []
    // Hover card state: { visible, type, screen }.
    property var card: ({ visible: false })

    // Show (type) or hide ("") the hover card of a block without hovering:
    // reviews, screenshots. On `screenName`, or the focused screen.
    signal cardRequested(string type, string screenName)

    function addSlot(slot: var): void {
        slots = [...slots, slot];
    }

    function removeSlot(slot: var): void {
        slots = slots.filter(s => s !== slot);
    }
}
