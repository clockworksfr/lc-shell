pragma Singleton

import QtQuick
import Quickshell

// Maps the block names used in layout.json to their implementation.
// A layout entry is either a name ("clock") or an object with a "type"
// and block-specific options ({ "type": "clock", "format": "HH:mm" }).
Singleton {
    readonly property var blocks: ({
            clock: "Clock.qml",
            media: "Media.qml",
            volume: "Volume.qml",
            workspaces: "Workspaces.qml"
        })

    function typeOf(entry: var): string {
        return typeof entry === "string" ? entry : (entry?.type ?? "");
    }

    function optionsOf(entry: var): var {
        return typeof entry === "string" ? {} : (entry ?? {});
    }

    function url(type: string): url {
        return Qt.resolvedUrl(blocks[type] ?? "Unknown.qml");
    }
}
