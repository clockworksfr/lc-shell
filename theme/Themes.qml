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
// Choices (IPC, settings app) are written to the user settings
// (Config.set), like any other setting.
Singleton {
    id: root

    readonly property var definitions: ({
            classic: Classic.definition,
            constellation: Constellation.definition,
            facade: Facade.definition,
            modulaire: Modulaire.definition,
            matrix: Matrix.definition
        })

    // "dark" | "light" | "auto" (follows appearance.schedule).
    readonly property string variantMode: Config.appearance.variant ?? "dark"
    property string scheduledVariant: "dark"
    readonly property string variant: variantMode === "auto" ? scheduledVariant : variantMode

    // Theme of surfaces that aren't Quickshell windows (QsWindow.window is
    // null there: the session lock's surfaces) and of windows before their
    // screen's theme is set: the normal screens' theme.
    readonly property var fallback: resolve(themeFor("normal"), false, "normal")

    function themeFor(mode: string): string {
        const id = (Config.appearance.themes ?? {})[mode] ?? "classic";
        return definitions[id] ? id : "classic";
    }

    // `mode` "modules" + touch: dashboard targets (72) instead of 48.
    // `screenVariant`: a screen profile's own "dark" / "light", over the
    // global one.
    function resolve(id: string, touch: bool, mode: string, screenVariant): var {
        const definition = definitions[id] ?? definitions.classic;
        const merged = deepMerge(Base.definition, definition);
        const v = screenVariant === "dark" || screenVariant === "light" ? screenVariant : variant;
        return {
            id: definition.id,
            name: definition.name,
            variant: v,
            touch: touch,
            color: merged.palettes[v],
            font: merged.font,
            space: merged.space,
            radius: merged.radius,
            border: merged.border,
            motion: merged.motion,
            drawer: merged.drawer,
            hit: touch ? (mode === "modules" ? merged.hit.modules : merged.hit.touch) : merged.hit.pointer,
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
        Config.set(`appearance.themes.${mode}`, id);
        return true;
    }

    function setVariant(mode: string): bool {
        if (!["dark", "light", "auto"].includes(mode))
            return false;
        Config.set("appearance.variant", mode);
        return true;
    }

    // Flips the current look and leaves automatic mode.
    function toggleVariant(): void {
        setVariant(variant === "dark" ? "light" : "dark");
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
