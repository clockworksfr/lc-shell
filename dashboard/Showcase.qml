pragma Singleton

import QtQuick
import Quickshell

// Dashboard showcase (tests, design reviews): while `type` is set, the
// dashboard shows that module alone at many cell shapes (wide, box, tiny,
// narrow, tall, strip…), keeping the showcase and theme buttons in the
// bottom-right corner. next() steps through the module types, then off.
Singleton {
    id: root

    // Module type shown, "" = off (the normal pages).
    property string type: ""
    readonly property var types: ["clock", "media", "weather", "system", "lyrics", "vu", "workspaces"]

    function next(): void {
        const index = types.indexOf(type);
        type = index + 1 < types.length ? types[index + 1] : "";
    }

    function stop(): void {
        type = "";
    }

    // Covers the 12 × 4 grid; (10, 3) and (11, 3) stay for the buttons.
    readonly property var shapes: [
        { x: 0, y: 0, w: 6, h: 2 },
        { x: 6, y: 0, w: 3, h: 2 },
        { x: 9, y: 0, w: 1, h: 1 },
        { x: 9, y: 1, w: 1, h: 3 },
        { x: 10, y: 0, w: 2, h: 3 },
        { x: 0, y: 2, w: 4, h: 2 },
        { x: 4, y: 2, w: 2, h: 2 },
        { x: 6, y: 2, w: 3, h: 1 },
        { x: 6, y: 3, w: 3, h: 1 }
    ]
    readonly property var cells: type ? [
        ...shapes.map(s => Object.assign({ type: type }, s)),
        { type: "showcase", x: 10, y: 3, w: 1, h: 1 },
        { type: "themeSwitch", x: 11, y: 3, w: 1, h: 1 }
    ] : []
}
