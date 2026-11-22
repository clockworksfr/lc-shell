pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// File search in $HOME with fd ("/" prefix). Hidden and git-ignored files
// are skipped. Enter opens the file, Shift+Enter opens its folder.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property bool active: Launcher.modeId === "files" && Launcher.term.length >= 2

    property var results: []
    property string searchedTerm
    // A search was requested while fd was still running.
    property bool dirty: false

    onActiveChanged: if (!active) results = []

    Connections {
        target: Launcher

        function onTermChanged(): void {
            if (root.active)
                debounce.restart();
        }
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: root.search()
    }

    function search(): void {
        if (!active)
            return;
        if (fd.running) {
            dirty = true;
            return;
        }
        searchedTerm = Launcher.term;
        fd.command = ["fd", "--ignore-case", "--fixed-strings", "--absolute-path", "--max-results", "80", "--", searchedTerm, home];
        fd.running = true;
    }

    function display(path: string): string {
        return path.startsWith(home) ? "~" + path.slice(home.length) : path;
    }

    Process {
        id: fd

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.active)
                    return;
                const query = Search.normalize(root.searchedTerm);
                root.results = text.split("\n").filter(line => line.length > 0).map(line => {
                    const isDir = line.endsWith("/");
                    const path = isDir ? line.slice(0, -1) : line;
                    const slash = path.lastIndexOf("/");
                    const name = path.slice(slash + 1);
                    const dir = path.slice(0, slash);
                    return {
                        key: `file:${path}`,
                        title: name,
                        subtitle: root.display(dir),
                        icon: isDir ? "folder" : "text-x-generic",
                        // Shorter paths first among equal matches.
                        score: Search.match(query, [[Search.normalize(name), 1, true]]) - path.split("/").length * 0.5,
                        activate: alt => Quickshell.execDetached(["xdg-open", alt ? dir : path])
                    };
                });
            }
        }

        onExited: {
            if (root.dirty) {
                root.dirty = false;
                root.search();
            }
        }
    }
}
