pragma Singleton

import QtQuick
import Quickshell

// Settings window state.
Singleton {
    property bool opened: false
    // "appearance" | "screens" | "bar" | "wallpaper" | "general"
    property string page: "appearance"

    readonly property var pages: ["appearance", "screens", "bar", "wallpaper", "general"]

    function open(target: string): void {
        if (pages.includes(target))
            page = target;
        opened = true;
    }

    function toggle(): void {
        opened = !opened;
    }
}
