pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers: one image per screen (keyed by screen model, stable across
// connector changes) or one for all, kept in the state dir.
//
// shell.json:
//   "wallpaper": { "enabled": true, "directory": "~/Images/Wallpapers" }
// Without a chosen image, screens show the theme background color.
Singleton {
    id: root

    readonly property var config: Config.data.wallpaper ?? {}
    readonly property bool enabled: config.enabled ?? true
    readonly property string home: Quickshell.env("HOME")
    readonly property string directory: expand(config.directory ?? "~/Pictures/Wallpapers")

    // { all: path, screens: { "<model or name>": path } }
    property var state: ({})
    // Absolute paths of the images found in `directory`, sorted.
    property var images: []

    function expand(path: string): string {
        return path.startsWith("~/") ? home + path.slice(1) : path;
    }

    function keyOf(screen: ShellScreen): string {
        return screen?.model || screen?.name || "";
    }

    function pathFor(screen: ShellScreen): string {
        return (state.screens ?? {})[keyOf(screen)] ?? state.all ?? "";
    }

    // screen null: every screen (and forget per-screen choices).
    function set(path: string, screen: ShellScreen): void {
        const absolute = expand(path);
        if (screen) {
            const screens = Object.assign({}, state.screens ?? {});
            screens[keyOf(screen)] = absolute;
            save(Object.assign({}, state, { screens: screens }));
        } else {
            save({ all: absolute, screens: {} });
        }
    }

    function random(screen: ShellScreen): void {
        if (images.length > 0)
            set(images[Math.floor(Math.random() * images.length)], screen);
    }

    function rescan(): void {
        scan.running = true;
    }

    function save(next: var): void {
        state = next;
        stateFile.setText(JSON.stringify(next, null, 2));
    }

    onDirectoryChanged: rescan()

    Process {
        id: scan
        command: ["find", "-L", root.directory, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector {
            onStreamFinished: root.images = text.split("\n").filter(line => line.length > 0).sort()
        }
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("wallpaper.json")
        printErrors: false
        onLoaded: {
            try {
                root.state = JSON.parse(text());
            } catch (e) {
                root.state = {};
            }
        }
    }
}
