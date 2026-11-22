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
// Language: shell.json "language" ("auto" | "en" | "fr"), overridden at
// runtime by `qs -c lc ipc call i18n set <code>` (kept in the state dir).
// "auto" follows the system locale. Dates and numbers use `locale`
// (shell.json "locale" to force one, e.g. "en_GB").
Singleton {
    id: root

    readonly property var languages: ["en", "fr"]

    property var state: ({})
    // language -> { key: text }
    property var tables: ({})

    readonly property string setting: state.language ?? Config.data.language ?? "auto"
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

    function setLanguage(code: string): bool {
        if (code !== "auto" && !languages.includes(code))
            return false;
        state = Object.assign({}, state, { language: code });
        stateFile.setText(JSON.stringify(state, null, 2));
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

    FileView {
        id: stateFile
        path: Quickshell.statePath("i18n.json")
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
