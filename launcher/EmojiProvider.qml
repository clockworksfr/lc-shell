pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Emoji picker (":" prefix). Enter types the emoji into the previously
// focused window and copies it; Shift+Enter only copies.
// Data: launcher/data/emoji.json, see launcher/data/README.md.
Singleton {
    id: root

    property var index: []

    // Newest Emoji version the installed font draws (noto-fonts-emoji
    // 2026-09 stops at 17.0); newer ones would render as empty boxes.
    readonly property real maxVersion: 17.0

    readonly property var results: {
        if (Launcher.modeId !== "emoji")
            return [];
        const query = Search.normalize(Launcher.term);
        const out = [];
        for (const item of index) {
            const key = `emoji:${item.emoji}`;
            const score = query ? Search.match(query, [[item.fr, 1, true], [item.en, 0.9, true], [item.keywords, 0.75]]) : 1;
            if (score <= 0)
                continue;
            out.push({
                key: key,
                title: item.name,
                subtitle: item.keywordsText,
                glyph: item.emoji,
                score: score + Launcher.usageBonus(key),
                activate: alt => root.pick(item.emoji, alt)
            });
        }
        return out;
    }

    function pick(emoji: string, copyOnly: bool): void {
        Quickshell.execDetached(["wl-copy", "--", emoji]);
        // Give focus back to the previous window before typing.
        if (!copyOnly)
            Quickshell.execDetached(["sh", "-c", "sleep 0.15; wtype -- \"$1\"", "sh", emoji]);
    }

    FileView {
        path: Quickshell.shellDir + "/launcher/data/emoji.json"
        onLoaded: {
            root.index = JSON.parse(text()).filter(e => e[4] <= root.maxVersion).map(([emoji, fr, en, keywords]) => ({
                        emoji: emoji,
                        name: fr || en,
                        keywordsText: keywords.split("|").slice(0, 6).join(", "),
                        fr: Search.normalize(fr),
                        en: Search.normalize(en),
                        keywords: Search.normalize(keywords)
                    }));
        }
    }
}
