pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services
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
            key: "action:reload",
            titleKey: "action.reload",
            icon: "view-refresh",
            run: () => Quickshell.reload(true)
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
        for (const action of [...staticActions, ...audioActions]) {
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
                // Slightly below apps with the same match.
                score: score * 0.95 + Launcher.usageBonus(action.key),
                activate: action.run
            });
        }
        return out;
    }
}
