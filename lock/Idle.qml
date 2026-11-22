pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.services

// Idle actions (ext-idle-notify). Idle inhibitors are respected, so the
// compositor's rules (e.g. idle_inhibit fullscreen) and apps keep it awake.
//
// Settings, in seconds (0 = never):
//   "idle": { "enabled": true, "lock": 600, "screenOff": 900,
//             "lockedScreenOff": 30, "suspend": 0 }
Singleton {
    id: root

    readonly property var config: Config.data.idle ?? {}
    readonly property bool enabled: config.enabled ?? true

    function screens(on: bool): void {
        Hyprland.dispatch(`hl.dsp.dpms({ action = "${on ? "on" : "off"}" })`);
    }

    IdleMonitor {
        enabled: root.enabled && (root.config.lock ?? 600) > 0
        timeout: root.config.lock ?? 600
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Lock.lock()
    }

    IdleMonitor {
        enabled: root.enabled && (root.config.screenOff ?? 900) > 0
        timeout: root.config.screenOff ?? 900
        respectInhibitors: true
        onIsIdleChanged: root.screens(!isIdle)
    }

    // Once locked, screens go off sooner.
    IdleMonitor {
        enabled: root.enabled && Lock.locked && (root.config.lockedScreenOff ?? 30) > 0
        timeout: root.config.lockedScreenOff ?? 30
        respectInhibitors: true
        onIsIdleChanged: root.screens(!isIdle)
    }

    IdleMonitor {
        enabled: root.enabled && (root.config.suspend ?? 0) > 0
        timeout: Math.max(1, root.config.suspend ?? 0)
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }
}
