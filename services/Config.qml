pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Reads config/shell.json (watched: saving it updates the shell live).
//
//   appearance  theme per screen mode, light/dark variant and its schedule
//   modes       per-mode module config: modes.normal.bar, modes.modules.osd...
//   screens     profiles, first match wins:
//               { match: { model: "XENEON EDGE" } | { name: "eDP-*" },
//                 mode: "normal" | "modules", theme, touch, <module overrides> }
//
// Screens are matched by model first: connector names change with the eGPU.
// A module override is merged key by key over the mode's config;
// null disables the module on that screen.
Singleton {
    id: root

    property var data: ({})

    readonly property var appearance: data.appearance ?? {}

    function matches(match: var, screen: ShellScreen): bool {
        if (!match || (!match.model && !match.name))
            return false;
        if (match.model && !(screen.model ?? "").includes(match.model))
            return false;
        if (match.name && !globMatch(match.name, screen.name))
            return false;
        return true;
    }

    function globMatch(pattern: string, text: string): bool {
        const regex = "^" + pattern.replace(/[.+^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*").replace(/\?/g, ".") + "$";
        return new RegExp(regex).test(text);
    }

    function profileFor(screen: ShellScreen): var {
        return (data.screens ?? []).find(p => matches(p.match, screen)) ?? {};
    }

    // Resolved config of one screen:
    // { mode, theme, touch, <module>: config | null, ... }
    function forScreen(screen: ShellScreen): var {
        if (!screen)
            return { mode: "normal", theme: null, touch: false };
        const profile = profileFor(screen);
        const mode = profile.mode ?? "normal";
        const base = (data.modes ?? {})[mode] ?? {};
        const result = { mode: mode, theme: profile.theme ?? null, touch: profile.touch ?? false };
        const reserved = ["match", "mode", "theme", "touch"];
        const keys = new Set([...Object.keys(base), ...Object.keys(profile)].filter(k => !reserved.includes(k)));

        for (const key of keys) {
            if (!(key in profile))
                result[key] = base[key];
            else if (profile[key] === null || profile[key] === false)
                result[key] = null;
            else if (isObject(base[key]) && isObject(profile[key]))
                result[key] = Object.assign({}, base[key], profile[key]);
            else
                result[key] = profile[key];
        }
        return result;
    }

    function forScreenName(name: string): var {
        return forScreen(Quickshell.screens.find(s => s.name === name) ?? null);
    }

    function isObject(value: var): bool {
        return value !== null && typeof value === "object" && !Array.isArray(value);
    }

    FileView {
        path: Quickshell.shellDir + "/config/shell.json"
        watchChanges: true
        onFileChanged: reload()

        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                // Keep the previous config so a typo doesn't wipe the screen.
                console.warn(`shell.json: invalid JSON, keeping previous config (${e})`);
            }
        }
        onLoadFailed: error => console.warn(`shell.json: cannot load (error ${error})`)
    }
}
