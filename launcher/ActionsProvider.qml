pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.lock
import qs.services
import qs.settings
import qs.theme
import qs.i18n

// Session and system actions (">" prefix, also mixed in the default mode).
//
// Lock and suspend go through logind, so they work with whichever lock
// screen listens to it (Caelestia today, lc-shell later, hyprlock...).
Singleton {
    id: root

    readonly property var staticActions: [
        {
            key: "action:lock",
            titleKey: "action.lock",
            icon: "system-lock-screen",
            run: () => Quickshell.execDetached(["loginctl", "lock-session"])
        },
        {
            key: "action:suspend",
            titleKey: "action.suspend",
            icon: "system-suspend",
            run: () => Quickshell.execDetached(["systemctl", "suspend"])
        },
        {
            key: "action:logout",
            titleKey: "action.logout",
            icon: "system-log-out",
            confirm: true,
            run: () => Hyprland.dispatch("hl.dsp.exit()")
        },
        {
            key: "action:reboot",
            titleKey: "action.reboot",
            icon: "system-reboot",
            confirm: true,
            run: () => Quickshell.execDetached(["systemctl", "reboot"])
        },
        {
            key: "action:poweroff",
            titleKey: "action.poweroff",
            icon: "system-shutdown",
            confirm: true,
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        },
        {
            key: "action:settings",
            titleKey: "action.settings",
            icon: "preferences-system",
            run: () => Settings.open("")
        },
        {
            key: "action:reload",
            titleKey: "action.reload",
            icon: "view-refresh",
            run: () => Quickshell.reload(true)
        },
        {
            key: "action:variant",
            // Names the variant it switches to.
            titleKey: Themes.variant === "dark" ? "action.variantLight" : "action.variantDark",
            icon: Themes.variant === "dark" ? "weather-clear" : "weather-clear-night",
            run: () => Themes.toggleVariant()
        },
        {
            key: "action:nextTheme",
            titleKey: "action.nextTheme",
            name: I18n.tr(`theme.${Themes.nextThemeId()}`),
            icon: "preferences-desktop-theme",
            run: () => Themes.nextTheme()
        },
        {
            key: "action:lockPreview",
            titleKey: "action.lockPreview",
            icon: "system-lock-screen",
            run: () => {
                Lock.status = "";
                Lock.previewing = true;
            }
        }
    ]

    // One entry per audio device, to switch the default output/input.
    readonly property var audioActions: [
        ...Audio.sinks.map(node => ({
                    key: `action:sink:${node.name}`,
                    titleKey: "action.sink",
                    name: Audio.nodeName(node),
                    icon: "audio-speakers",
                    current: node === Audio.sink,
                    run: () => Audio.setDefaultSink(node)
                })),
        ...Audio.sources.map(node => ({
                    key: `action:source:${node.name}`,
                    titleKey: "action.source",
                    name: Audio.nodeName(node),
                    icon: "audio-input-microphone",
                    current: node === Audio.source,
                    run: () => Audio.setDefaultSource(node)
                }))
    ]

    readonly property var results: {
        if (Launcher.modeId !== "all" && Launcher.modeId !== "actions")
            return [];
        const query = Search.normalize(Launcher.term);
        // In the mixed mode, actions only show up when searched for.
        if (Launcher.modeId === "all" && !query)
            return [];
        const out = [];
        const all = [...staticActions, ...audioActions];
        for (const [order, action] of all.entries()) {
            const title = I18n.tr(action.titleKey, { name: action.name ?? "" });
            // Keywords of every language: "veille" and "sleep" both find it.
            const keywords = Search.normalize(`${I18n.all(action.titleKey)} ${I18n.all(action.titleKey + ".keywords")}`);
            const score = Search.match(query, [[Search.normalize(title), 1, true], [keywords, 0.7]]);
            if (score <= 0)
                continue;
            const pending = Launcher.confirmKey === action.key;
            out.push({
                key: action.key,
                title: title,
                subtitle: pending ? I18n.tr("launcher.confirm") : action.current ? I18n.tr("launcher.current") : "",
                urgent: pending,
                icon: action.icon,
                confirm: action.confirm ?? false,
                // Slightly below apps with the same match; audio devices below
                // session actions.
                // Defined order breaks ties (lock, suspend… before previews).
                score: score * (action.key.startsWith("action:sink") || action.key.startsWith("action:source") ? 0.75 : 0.95) + Launcher.usageBonus(action.key) - order * 0.001,
                activate: action.run
            });
        }
        return out;
    }
}
