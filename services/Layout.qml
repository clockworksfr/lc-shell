pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reads config/layout.json and resolves the layout of each screen.
//
// Format:
//   "default": { <module>: { ...options } }       applies to every screen
//   "screens": { "<output>": { <module>: ... } }  per-screen overrides
//
// An override is merged key by key over the default module config.
// Setting a module to null disables it on that screen.
// The file is watched: saving it updates the shell live.
Singleton {
    id: root

    property var data: ({})

    function forScreen(name: string): var {
        const defaults = root.data.default ?? {};
        const overrides = (root.data.screens ?? {})[name] ?? {};
        const result = {};
        const keys = new Set([...Object.keys(defaults), ...Object.keys(overrides)]);

        for (const key of keys) {
            if (!(key in overrides)) {
                result[key] = defaults[key];
            } else if (overrides[key] === null || overrides[key] === false) {
                result[key] = null;
            } else if (isObject(defaults[key]) && isObject(overrides[key])) {
                result[key] = Object.assign({}, defaults[key], overrides[key]);
            } else {
                result[key] = overrides[key];
            }
        }
        return result;
    }

    function isObject(value: var): bool {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    FileView {
        path: Quickshell.shellDir + "/config/layout.json"
        watchChanges: true
        onFileChanged: reload()

        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                // Keep the previous layout so a typo doesn't wipe the screen.
                console.warn(`layout.json: invalid JSON, keeping previous layout (${e})`);
            }
        }
        onLoadFailed: error => console.warn(`layout.json: cannot load (error ${error})`)
    }
}
