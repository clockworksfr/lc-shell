pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.i18n

// Clipboard history (cliphist, fed by `wl-paste --watch cliphist store`):
// "+" prefix. Enter copies the entry back; Shift+Enter deletes it.
Singleton {
    id: root

    readonly property bool active: Launcher.opened && Launcher.modeId === "clipboard"
    // [{ id, line, text }] newest first.
    property var entries: []

    readonly property var results: {
        if (!active)
            return [];
        const q = Launcher.term.toLowerCase();
        return entries.filter(e => !q || e.text.toLowerCase().includes(q)).slice(0, 60).map((e, i) => ({
                key: `clip:${e.id}`,
                title: e.image ? I18n.tr("launcher.clip.image") : e.text.replace(/\s+/g, " ").slice(0, 160),
                subtitle: e.image ? e.text : I18n.tr("launcher.clip.hint"),
                icon: e.image ? "image-x-generic" : "edit-paste",
                score: 1000 - i,
                activate: alt => alt ? root.remove(e) : root.copy(e)
            }));
    }

    onActiveChanged: if (active) list.running = true

    function copy(entry: var): void {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", entry.line]);
    }

    function remove(entry: var): void {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", entry.line]);
        entries = entries.filter(e => e.id !== entry.id);
    }

    Process {
        id: list
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.entries = text.split("\n").filter(l => !!l).map(l => {
                const tab = l.indexOf("\t");
                const t = tab >= 0 ? l.slice(tab + 1) : l;
                return { id: tab >= 0 ? l.slice(0, tab) : l, line: l, text: t, image: /^\[\[ binary data/.test(t) };
            })
        }
    }
}
