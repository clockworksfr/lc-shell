pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Animation timing shared by every surface.
//
// - Per theme: theme.motion { fast, base, slow, easing, overshoot, stagger }.
// - Reduced motion (setting appearance.reducedMotion, else GNOME's
//   enable-animations): short fades only (≤ 90 ms), no movement.
// - On a screen showing a fullscreen game: no animation at all (0 ms).
// - Exits: InCubic, 0.75 × the entry duration.
Singleton {
    id: root

    // GNOME / GTK "enable animations" (false = reduce).
    property bool systemAnimations: true
    readonly property bool reduced: Config.get("appearance.reducedMotion") ?? !systemAnimations

    // Duration (ms) of `kind` ("fast" | "base" | "slow") for a theme, on a
    // screen (by name; "" = no screen check).
    function ms(theme: var, kind: string, screenName: string): int {
        if (screenName && Screens.hasFullscreen(screenName))
            return 0;
        const d = theme?.motion?.[kind] ?? theme?.motion?.duration ?? 200;
        return reduced ? Math.min(d, 90) : d;
    }

    function exitMs(theme: var, kind: string, screenName: string): int {
        return Math.round(ms(theme, kind, screenName) * 0.75);
    }

    // Easing.Type of a theme's entry curve.
    function easing(theme: var): int {
        if (reduced)
            return Easing.OutQuad;
        switch (theme?.motion?.easing) {
        case "OutBack":
            return Easing.OutBack;
        case "OutQuad":
            return Easing.OutQuad;
        case "OutQuart":
            return Easing.OutQuart;
        case "OutQuint":
            return Easing.OutQuint;
        default:
            return Easing.OutCubic;
        }
    }

    function overshoot(theme: var): real {
        return reduced ? 0 : (theme?.motion?.overshoot ?? 0);
    }

    // Movement in px, 0 when motion is reduced (fades only).
    function travel(px: real): real {
        return reduced ? 0 : px;
    }

    Process {
        running: true
        command: ["gsettings", "get", "org.gnome.desktop.interface", "enable-animations"]
        stdout: StdioCollector {
            onStreamFinished: root.systemAnimations = text.trim() !== "false"
        }
    }
}
