pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Configuration = config/defaults.json (repo, generic) with the user's
// settings layered on top: $XDG_CONFIG_HOME/lc/settings.json (written by
// the shell: settings app, IPC). Both are watched: edits apply live.
// Objects merge key by key; arrays (block lists, screens, pages) replace.
//
//   language, wallpaper, notifications…
//   appearance  themes (screens: "normal", dashboards: "modules"),
//               light/dark variant and its schedule
//   modes       default module config of screens: modes.normal.bar, .osd…
//   dashboards  modules per workspace (dashboard/Dashboard.qml)
//   screens     profiles, first match wins:
//               { match: { model: "XENEON EDGE" } | { name: "eDP-*" },
//                 theme, touch, <module overrides> }
//               ("bar": false = no bar there; an object overrides the
//               default bar). A legacy "mode" is ignored.
//
// Screens are matched by model first: connector names change with the eGPU.
// A module override is merged key by key over the mode's config;
// null disables the module on that screen.
Singleton {
    id: root

    property var defaults: ({})
    property var user: ({})
    readonly property var data: merge(defaults, user)

    readonly property var appearance: data.appearance ?? {}

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
    readonly property string userPath: `${configHome}/lc/settings.json`

    function merge(base: var, over: var): var {
        if (!isObject(base) || !isObject(over))
            return over === undefined ? base : over;
        const out = Object.assign({}, base);
        for (const key in over)
            out[key] = merge(base[key], over[key]);
        return out;
    }

    // Screen profiles as the user settings will hold them: the user's list,
    // or a copy of the defaults' list on first edit.
    function editableScreens(): var {
        return JSON.parse(JSON.stringify(user.screens ?? defaults.screens ?? []));
    }

    // Sets a key of the screen's profile, creating a profile matched by model
    // (stable) when none exists. `undefined` removes the key.
    function setScreen(screen: ShellScreen, key: string, value: var): void {
        const screens = editableScreens();
        let profile = screens.find(p => matches(p.match, screen));
        if (!profile) {
            profile = { match: screen.model ? { model: screen.model } : { name: screen.name } };
            screens.unshift(profile);
        }
        if (value === undefined)
            delete profile[key];
        else
            profile[key] = value;
        set("screens", screens);
    }

    // Value at a dotted path of the merged config ("appearance.variant").
    function get(path: string): var {
        return path.split(".").reduce((o, k) => o?.[k], data);
    }

    // Writes a user setting; `undefined` removes it (back to the default).
    function set(path: string, value: var): void {
        const next = JSON.parse(JSON.stringify(user));
        const keys = path.split(".");
        let node = next;
        for (const key of keys.slice(0, -1)) {
            if (!isObject(node[key]))
                node[key] = {};
            node = node[key];
        }
        const last = keys[keys.length - 1];
        if (value === undefined)
            delete node[last];
        else
            node[last] = value;
        user = next;
        // Several set() in a row (one IPC call can make two) end in one write.
        Qt.callLater(root.flush);
    }

    // Last content we wrote: the file watcher reports our own writes too,
    // and reloading them late used to overwrite newer in-memory settings.
    property string lastWritten

    function flush(): void {
        const text = JSON.stringify(user, null, 2) + "\n";
        if (text === lastWritten)
            return;
        lastWritten = text;
        userFile.setText(text);
    }

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
        // Every screen is a normal one now (dashboards follow workspaces).
        const mode = "normal";
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
        path: Quickshell.shellDir + "/config/defaults.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.defaults = JSON.parse(text());
            } catch (e) {
                // Keep the previous config so a typo doesn't wipe the screen.
                console.warn(`defaults.json: invalid JSON, keeping previous config (${e})`);
            }
        }
        onLoadFailed: error => console.warn(`defaults.json: cannot load (error ${error})`)
    }

    FileView {
        id: userFile
        path: root.userPath
        watchChanges: true
        // Temp file + rename: a reader never sees half a file.
        atomicWrites: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const content = text();
            // Our own write coming back: memory is already up to date.
            if (content === root.lastWritten)
                return;
            try {
                root.user = JSON.parse(content);
            } catch (e) {
                console.warn(`${root.userPath}: invalid JSON, keeping previous settings (${e})`);
            }
        }
    }

    // The settings directory may not exist yet.
    Process {
        running: true
        command: ["mkdir", "-p", `${root.configHome}/lc`]
    }
}
