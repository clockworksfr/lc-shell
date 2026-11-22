pragma Singleton

import QtQuick
import Quickshell
import qs.i18n

// Per kind of clipboard item: icon, color (a Clipboard.tagColors name),
// one-line summary for the card footer.
Singleton {
    readonly property var kinds: ["text", "code", "link", "image", "file", "color", "char"]

    function icon(kind: string): string {
        return ({
                text: "notes",
                code: "code",
                link: "link",
                image: "image",
                file: "description",
                color: "palette",
                char: "mood"
            })[kind] ?? "content_paste";
    }

    function color(kind: string): string {
        return ({
                text: "grey",
                code: "purple",
                link: "blue",
                image: "teal",
                file: "orange",
                color: "pink",
                char: "yellow"
            })[kind] ?? "grey";
    }

    function summary(entry: var): string {
        if (!entry)
            return "";
        switch (entry.kind) {
        case "image":
            return entry.w ? `${entry.w} × ${entry.h}  ·  ${I18n.bytes(entry.size, false)}` : I18n.bytes(entry.size, false);
        case "file":
            return I18n.plural("clip.files", (entry.text ?? "").split(/\r?\n/).filter(l => l.trim() && !l.startsWith("#")).length);
        case "char":
            return [...(entry.text ?? "").trim()].map(c => `U+${c.codePointAt(0).toString(16).toUpperCase().padStart(4, "0")}`).slice(0, 2).join(" ");
        case "color":
        case "link":
            return "";
        default:
            {
                const lines = (entry.text ?? "").split("\n").length;
                const chars = entry.truncated ? entry.size : (entry.text ?? "").length;
                return lines > 1 ? `${I18n.plural("clip.chars", chars)}  ·  ${I18n.plural("clip.lines", lines)}` : I18n.plural("clip.chars", chars);
            }
        }
    }
}
