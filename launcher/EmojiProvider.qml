pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.i18n

// Emoji picker (":" prefix). Enter types the emoji into the previously
// focused window and copies it; Shift+Enter only copies.
// Names are shown in the shell language; search matches every language.
// Data: launcher/data/emoji.json, see launcher/data/README.md.
Singleton {
    id: root

    // [{ emoji, names: { en: [name, keywords] , fr: ... }, search: [[text, weight, fuzzy]...] }]
    property var index: []

    // Newest Emoji version the installed font draws (noto-fonts-emoji
    // 2026-09 stops at 17.0); newer ones would render as empty boxes.
    readonly property real maxVersion: 17.0

    readonly property var results: {
        if (Launcher.modeId !== "emoji")
            return [];
        const language = I18n.language;
        const query = Search.normalize(Launcher.term);
        const out = [];
        for (const item of index) {
            const key = `emoji:${item.emoji}`;
            const score = query ? Search.match(query, item.search) : 1;
            if (score <= 0)
                continue;
            const [name, keywords] = item.names[language] ?? item.names.en;
            out.push({
                key: key,
                title: name || item.names.en[0],
                subtitle: keywords.split("|").slice(0, 6).join(", "),
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
            const data = JSON.parse(text());
            root.index = data.emoji.filter(([, version]) => version <= root.maxVersion).map(([emoji, , names]) => ({
                        emoji: emoji,
                        names: names,
                        // Names (fuzzy) then keywords, in every language.
                        search: [
                            ...Object.values(names).map(([name]) => [Search.normalize(name), 1, true]),
                            ...Object.values(names).map(([, keywords]) => [Search.normalize(keywords), 0.75, false])
                        ]
                    }));
        }
    }
}
