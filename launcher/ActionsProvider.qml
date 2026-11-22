pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Session and system actions (">" prefix, also mixed in the default mode).
//
// Lock and suspend go through logind, so they work with whichever lock
// screen listens to it (Caelestia today, lc-shell later, hyprlock...).
Singleton {
    id: root

    readonly property var staticActions: [
        {
            key: "action:lock",
            title: "Verrouiller",
            keywords: "lock ecran session",
            icon: "system-lock-screen",
            run: () => Quickshell.execDetached(["loginctl", "lock-session"])
        },
        {
            key: "action:suspend",
            title: "Mettre en veille",
            keywords: "suspend sleep dormir",
            icon: "system-suspend",
            run: () => Quickshell.execDetached(["systemctl", "suspend"])
        },
        {
            key: "action:logout",
            title: "Quitter Hyprland",
            keywords: "logout deconnexion session exit",
            icon: "system-log-out",
            confirm: true,
            run: () => Hyprland.dispatch("hl.dsp.exit()")
        },
        {
            key: "action:reboot",
            title: "Redémarrer",
            keywords: "reboot restart",
            icon: "system-reboot",
            confirm: true,
            run: () => Quickshell.execDetached(["systemctl", "reboot"])
        },
        {
            key: "action:poweroff",
            title: "Éteindre",
            keywords: "shutdown poweroff arreter",
            icon: "system-shutdown",
            confirm: true,
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        },
        {
            key: "action:reload",
            title: "Recharger le shell",
            keywords: "reload restart quickshell lc",
            icon: "view-refresh",
            run: () => Quickshell.reload(true)
        }
    ]

    // One entry per audio device, to switch the default output/input.
    readonly property var audioActions: [
        ...Audio.sinks.map(node => ({
                    key: `action:sink:${node.name}`,
                    title: `Sortie audio : ${Audio.nodeName(node)}`,
                    keywords: "audio son sortie output haut-parleur casque",
                    icon: "audio-speakers",
                    current: node === Audio.sink,
                    run: () => Audio.setDefaultSink(node)
                })),
        ...Audio.sources.map(node => ({
                    key: `action:source:${node.name}`,
                    title: `Entrée audio : ${Audio.nodeName(node)}`,
                    keywords: "audio micro entree input microphone",
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
            const score = Search.match(query, [[Search.normalize(action.title), 1, true], [action.keywords, 0.7]]);
            if (score <= 0)
                continue;
            const pending = Launcher.confirmKey === action.key;
            out.push({
                key: action.key,
                title: action.title,
                subtitle: pending ? "Entrée à nouveau pour confirmer" : action.current ? "actuel" : "",
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
