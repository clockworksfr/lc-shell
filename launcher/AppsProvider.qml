pragma Singleton

import QtQuick
import Quickshell

// Desktop applications (.desktop entries).
Singleton {
    id: root

    readonly property var index: DesktopEntries.applications.values.filter(e => !e.noDisplay).map(e => ({
                entry: e,
                name: Search.normalize(e.name),
                generic: Search.normalize(e.genericName),
                keywords: Search.normalize(e.keywords.join(" ")),
                id: Search.normalize(e.id),
                comment: Search.normalize(e.comment)
            }))

    readonly property var results: {
        if (Launcher.modeId !== "all")
            return [];
        const query = Search.normalize(Launcher.term);
        const out = [];
        for (const app of index) {
            const score = Search.match(query, [[app.name, 1, true], [app.generic, 0.8], [app.keywords, 0.7], [app.id, 0.6, true], [app.comment, 0.4]]);
            if (score <= 0)
                continue;
            const entry = app.entry;
            const key = `app:${entry.id}`;
            out.push({
                key: key,
                title: entry.name,
                subtitle: entry.genericName || entry.comment,
                icon: entry.icon || "application-x-executable",
                score: score + Launcher.usageBonus(key),
                activate: () => entry.execute()
            });
        }
        return out;
    }
}
