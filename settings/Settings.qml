pragma Singleton

import QtQuick
import Quickshell

// Settings window state: open page, search highlight.
Singleton {
    id: root

    property bool opened: false
    property string page: "appearance"
    // i18n key of a setting to point out (search result), "" = none.
    property string highlight: ""
    // Text in the settings search.
    property string query: ""

    readonly property var pages: ["appearance", "bar", "screens", "dashboard", "wallpaper", "notifications", "modes", "network", "bluetooth", "sound", "clipboard", "screenshot", "lock", "weather", "lights", "system", "shortcuts"]
    readonly property var icons: ({
            appearance: "palette",
            bar: "toolbar",
            screens: "monitor",
            dashboard: "dashboard",
            wallpaper: "wallpaper",
            notifications: "notifications",
            modes: "coffee",
            network: "lan",
            bluetooth: "bluetooth",
            sound: "volume_up",
            clipboard: "content_paste",
            screenshot: "screenshot_region",
            lock: "lock",
            weather: "partly_cloudy_day",
            lights: "lightbulb",
            system: "settings_accessibility",
            shortcuts: "keyboard"
        })

    // A highlighted field asks to be scrolled into view.
    signal reveal(Item item)

    function open(target: string): void {
        // Older page names.
        const name = target === "general" ? "system" : target;
        if (pages.includes(name)) {
            page = name;
            query = "";
        }
        opened = true;
    }

    function toggle(): void {
        opened = !opened;
    }

    // Opens a setting's page and points it out for a moment.
    function show(target: string, key: string): void {
        open(target);
        highlight = "";
        Qt.callLater(() => root.highlight = key);
        clear.restart();
    }

    Timer {
        id: clear
        interval: 2200
        onTriggered: root.highlight = ""
    }
}
