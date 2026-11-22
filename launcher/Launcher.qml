pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Launcher state: input, mode, aggregated results, usage history.
//
// A result is a plain object:
//   key       stable id, used for usage ranking and confirmation
//   title, subtitle
//   icon      icon theme name, or glyph: text shown instead (emoji...),
//             or image: a local file shown as a thumbnail
//   score     higher first
//   confirm   true: first activation only asks for confirmation
//   activate  function(alt), alt = Shift held
Singleton {
    id: root

    property bool opened: false
    property string screenName
    property string text
    // Key of the result waiting for a second Enter.
    property string confirmKey

    readonly property var modes: [
        { prefix: ":", id: "emoji" },
        { prefix: "/", id: "files" },
        { prefix: "=", id: "calc" },
        { prefix: ">", id: "actions" },
        { prefix: "@", id: "wallpapers" }
    ]
    readonly property var mode: modes.find(m => text.startsWith(m.prefix)) ?? null
    readonly property string modeId: mode?.id ?? "all"
    readonly property string term: (mode ? text.slice(mode.prefix.length) : text).trim()

    readonly property int maxResults: 60

    readonly property var results: {
        let list;
        switch (modeId) {
        case "emoji":
            list = EmojiProvider.results;
            break;
        case "files":
            list = FilesProvider.results;
            break;
        case "calc":
            list = CalcProvider.results;
            break;
        case "actions":
            list = ActionsProvider.results;
            break;
        case "wallpapers":
            list = WallpaperProvider.results;
            break;
        default:
            list = [...CalcProvider.results, ...AppsProvider.results, ...ActionsProvider.results];
        }
        return list.slice().sort((a, b) => b.score - a.score || a.title.localeCompare(b.title)).slice(0, maxResults);
    }

    onTextChanged: confirmKey = ""

    function open(initialText: string): void {
        text = initialText ?? "";
        screenName = Hyprland.focusedMonitor?.name ?? "";
        opened = true;
    }

    function close(): void {
        opened = false;
        text = "";
        confirmKey = "";
    }

    function toggle(): void {
        if (opened)
            close();
        else
            open("");
    }

    function activate(result: var, alt: bool): void {
        if (!result)
            return;
        if (result.confirm && confirmKey !== result.key) {
            confirmKey = result.key;
            return;
        }
        recordUse(result.key);
        close();
        result.activate(alt);
    }

    // --- Usage history (ranking bonus) ---

    property var usage: ({})

    function usageBonus(key: string): real {
        const count = usage[key] ?? 0;
        return Math.min(20, Math.log2(1 + count) * 5);
    }

    function recordUse(key: string): void {
        const next = Object.assign({}, usage);
        next[key] = (next[key] ?? 0) + 1;
        usage = next;
        usageFile.setText(JSON.stringify(next));
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }
}
