pragma Singleton

import QtQuick
import Quickshell
import qs.i18n
import qs.services

// Wallpaper picker ("@" prefix): images of the wallpaper directory, with
// thumbnails. Enter: every screen; Shift+Enter: the launcher's screen only.
Singleton {
    id: root

    readonly property bool active: Launcher.modeId === "wallpapers"

    onActiveChanged: if (active) Wallpaper.rescan()

    readonly property var results: {
        if (!active)
            return [];
        const query = Search.normalize(Launcher.term);
        const base = Wallpaper.directory.length + 1;
        const out = [];
        for (const path of Wallpaper.images) {
            const relative = path.slice(base);
            const slash = relative.lastIndexOf("/");
            const name = relative.slice(slash + 1);
            const score = Search.match(query, [[Search.normalize(name), 1, true], [Search.normalize(relative), 0.7]]);
            if (score <= 0)
                continue;
            out.push({
                key: `wallpaper:${path}`,
                title: name,
                subtitle: slash > 0 ? relative.slice(0, slash) : "",
                image: path,
                score: score,
                activate: alt => Wallpaper.set(path, alt ? Quickshell.screens.find(s => s.name === Launcher.screenName) ?? null : null)
            });
        }
        return out;
    }
}
