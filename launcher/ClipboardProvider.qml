pragma Singleton

import QtQuick
import Quickshell
import qs.clipboard
import qs.i18n

// Clipboard history (the clipboard manager's store, qs.clipboard):
// "+" prefix. Enter copies the entry back; Shift+Enter deletes it.
// The full manager is Super+Shift+V (lc:clipboard).
Singleton {
    id: root

    readonly property bool active: Launcher.opened && Launcher.modeId === "clipboard"

    readonly property var results: {
        if (!active)
            return [];
        const q = Search.normalize(Launcher.term);
        return Clipboard.items.filter(e => !q || Search.normalize(`${e.text ?? ""} ${e.app ?? ""}`).includes(q)).slice(0, 60).map((e, i) => ({
                key: `clip:${e.id}`,
                title: e.kind === "image" ? I18n.tr("launcher.clip.image") : (e.text ?? "").replace(/\s+/g, " ").slice(0, 160),
                subtitle: `${I18n.tr(`clip.kind.${e.kind}`)} · ${I18n.relativeTime(e.last)} · ${I18n.tr("launcher.clip.hint")}`,
                icon: e.kind === "image" ? "" : "edit-paste",
                image: e.kind === "image" ? Clipboard.blobPath(e) : "",
                score: 1000 - i,
                activate: alt => alt ? Clipboard.remove(e.id) : Clipboard.copy(e.id, false, false)
            }));
    }
}
