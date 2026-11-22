pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Interface language (English and French for now).
//
// Strings live in i18n/<language>.json as flat "key": "text" pairs, with
// {placeholders}. Files are watched: edits show up live. A missing key
// falls back to English, then to the key itself (visible, easy to spot).
//
// Language: setting "language" ("auto" | "en" | "fr"), also set by
// `qs -c lc ipc call i18n set <code>` and the settings app.
// "auto" follows the system locale. Dates and numbers use `locale`
// (settings "locale" to force one, e.g. "en_GB").
Singleton {
    id: root

    readonly property var languages: ["en", "fr"]

    // language -> { key: text }
    property var tables: ({})

    readonly property string setting: Config.data.language ?? "auto"
    readonly property string systemLanguage: {
        const code = Qt.locale().name.split("_")[0];
        return languages.includes(code) ? code : "en";
    }
    readonly property string language: setting === "auto" ? systemLanguage : (languages.includes(setting) ? setting : "en")
    readonly property var locale: Qt.locale(Config.data.locale ?? (language === "fr" ? "fr_FR" : "en_US"))

    function tr(key: string, args: var): string {
        let text = (tables[language] ?? {})[key] ?? (tables.en ?? {})[key] ?? key;
        if (args) {
            for (const name in args)
                text = text.split(`{${name}}`).join(`${args[name]}`);
        }
        return text;
    }

    // Whether a key has a text (current language or English).
    function has(key: string): bool {
        return key in (tables[language] ?? {}) || key in (tables.en ?? {});
    }

    // The text of a key in every language, e.g. to search keywords in both.
    function all(key: string): string {
        return languages.map(code => (tables[code] ?? {})[key] ?? "").join(" ");
    }

    // 0..1 -> "42%" / "42 %"
    function percent(value: real): string {
        return tr("format.percent", { value: Math.round(value * 100) });
    }

    function number(value: real, decimals: int): string {
        return Number(value).toLocaleString(locale, "f", decimals);
    }

    // "key.one" / "key.other" by count (French: 0 and 1 are singular).
    function plural(key: string, n: int): string {
        const one = language === "fr" ? n <= 1 : n === 1;
        return tr(`${key}.${one ? "one" : "other"}`, { n: n });
    }

    // Bytes (or bytes per second with `perSecond`) in a readable unit.
    function bytes(value: real, perSecond: bool): string {
        const units = tr("format.byteUnits").split(" ");
        let unit = 0;
        let v = Math.max(0, value);
        while (v >= 1000 && unit < units.length - 1) {
            v /= 1000;
            unit++;
        }
        const text = `${number(v, v < 10 && unit > 0 ? 1 : 0)}${tr("format.unitSpace")}${units[unit]}`;
        return perSecond ? tr("format.perSecond", { value: text }) : text;
    }

    // "just now", "5 min ago", "14:32" (today), "22 Nov 14:32".
    function relativeTime(ms: real): string {
        const minutes = Math.floor((Date.now() - ms) / 60000);
        if (minutes < 1)
            return tr("time.now");
        if (minutes < 60)
            return tr("time.minutesAgo", { n: minutes });
        const date = new Date(ms);
        const sameDay = date.toDateString() === new Date().toDateString();
        return locale.toString(date, sameDay ? "HH:mm" : tr("format.dateShort"));
    }

    function setLanguage(code: string): bool {
        if (code !== "auto" && !languages.includes(code))
            return false;
        Config.set("language", code);
        return true;
    }

    Instantiator {
        model: root.languages

        FileView {
            required property string modelData

            path: `${Quickshell.shellDir}/i18n/${modelData}.json`
            watchChanges: true
            onFileChanged: reload()
            onLoaded: {
                try {
                    const next = Object.assign({}, root.tables);
                    next[modelData] = JSON.parse(text());
                    root.tables = next;
                } catch (e) {
                    console.warn(`i18n/${modelData}.json: invalid JSON, keeping previous strings (${e})`);
                }
            }
        }
    }
}
