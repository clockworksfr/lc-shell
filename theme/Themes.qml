pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.theme.defs

// Theme registry, light/dark variant and its schedule.
//
// Each screen gets its own resolved theme (see ScreenScope): the theme of
// its mode ("normal" / "modules"), unless its profile names one.
// Runtime choices (IPC, future settings UI) are kept in the state dir and
// win over config/shell.json.
Singleton {
    id: root

    readonly property var definitions: ({
            classic: Classic.definition,
            matrix: Matrix.definition
        })

    // Persisted runtime choices: { variant, themes: { normal, modules } }.
    property var state: ({})

    // "dark" | "light" | "auto" (follows appearance.schedule).
    readonly property string variantMode: state.variant ?? Config.appearance.variant ?? "dark"
    property string scheduledVariant: "dark"
    readonly property string variant: variantMode === "auto" ? scheduledVariant : variantMode

    readonly property var fallback: resolve("classic", false)

    function themeFor(mode: string): string {
        const id = (state.themes ?? {})[mode] ?? (Config.appearance.themes ?? {})[mode] ?? "classic";
        return definitions[id] ? id : "classic";
    }

    function resolve(id: string, touch: bool): var {
        const definition = definitions[id] ?? definitions.classic;
        const merged = deepMerge(Base.definition, definition);
        return {
            id: definition.id,
            name: definition.name,
            variant: variant,
            touch: touch,
            color: merged.palettes[variant],
            font: merged.font,
            space: merged.space,
            radius: merged.radius,
            border: merged.border,
            motion: merged.motion,
            hit: touch ? merged.hit.touch : merged.hit.pointer,
            bar: merged.bar,
            style: merged.style
        };
    }

    function deepMerge(base: var, over: var): var {
        const out = Object.assign({}, base);
        for (const key in over) {
            const a = base[key];
            const b = over[key];
            const bothObjects = a && b && typeof a === "object" && typeof b === "object" && !Array.isArray(a) && !Array.isArray(b);
            out[key] = bothObjects ? deepMerge(a, b) : b;
        }
        return out;
    }

    // --- Runtime changes ---

    function setTheme(mode: string, id: string): bool {
        if (!definitions[id])
            return false;
        const themes = Object.assign({}, state.themes ?? {});
        themes[mode] = id;
        saveState(Object.assign({}, state, { themes: themes }));
        return true;
    }

    function setVariant(mode: string): bool {
        if (!["dark", "light", "auto"].includes(mode))
            return false;
        saveState(Object.assign({}, state, { variant: mode }));
        return true;
    }

    // Flips the current look and leaves automatic mode.
    function toggleVariant(): void {
        setVariant(variant === "dark" ? "light" : "dark");
    }

    function saveState(next: var): void {
        state = next;
        stateFile.setText(JSON.stringify(next, null, 2));
    }

    FileView {
        id: stateFile
        path: Quickshell.statePath("appearance.json")
        printErrors: false
        onLoaded: {
            try {
                root.state = JSON.parse(text());
            } catch (e) {
                root.state = {};
            }
        }
    }

    // --- Schedule ---

    // appearance.schedule:
    //   { "type": "time", "light": "07:30", "dark": "19:30" }
    //   { "type": "sun", "latitude": 48.85, "longitude": 2.35 }
    function updateSchedule(): void {
        const schedule = Config.appearance.schedule ?? {};
        const now = new Date();
        let light;

        if (schedule.type === "sun" && schedule.latitude !== undefined && schedule.longitude !== undefined) {
            const sun = Sun.times(now, schedule.latitude, schedule.longitude);
            light = sun.polar ? sun.polar === "day" : now >= sun.sunrise && now < sun.sunset;
        } else {
            const minutes = text => {
                const [h, m] = (text ?? "").split(":").map(Number);
                return h * 60 + (m || 0);
            };
            const current = now.getHours() * 60 + now.getMinutes();
            const start = minutes(schedule.light ?? "07:30");
            const end = minutes(schedule.dark ?? "19:30");
            light = start <= end ? current >= start && current < end : current >= start || current < end;
        }
        scheduledVariant = light ? "light" : "dark";
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.updateSchedule()
    }

    Connections {
        target: Config

        function onAppearanceChanged(): void {
            root.updateSchedule();
        }
    }
}
