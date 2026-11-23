pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Idle actions (ext-idle-notify). Idle inhibitors are respected, so the
// compositor's rules (e.g. idle_inhibit fullscreen) and apps keep it awake.
//
// Settings, in seconds (0 = never):
//   "idle": { "enabled": true, "lock": 900, "screenOff": 930,
//             "lockedScreenOff": 30, "suspend": 1800,
//             "inhibitWhenAudio": true, "inhibitWhenCharging": false }
// inhibitWhenAudio: nothing happens while a player plays (MPRIS);
// inhibitWhenCharging: nor while the battery charges (or on AC power).
Singleton {
    id: root

    readonly property var config: Config.data.idle ?? {}
    readonly property bool enabled: config.enabled ?? true
    readonly property int lockAfter: config.lock ?? 900
    readonly property int screenOffAfter: config.screenOff ?? 930
    readonly property int lockedScreenOffAfter: config.lockedScreenOff ?? 30
    readonly property int suspendAfter: config.suspend ?? 1800
    readonly property bool inhibitWhenAudio: config.inhibitWhenAudio ?? true
    readonly property bool inhibitWhenCharging: config.inhibitWhenCharging ?? false

    readonly property bool playing: Players.list.some(p => p.isPlaying)
    readonly property bool onPower: Power.hasBattery ? !Power.onBattery : false
    // Why idle actions are held right now ("" = they aren't).
    // Caffeine (quick settings): stay awake until turned off (not kept
    // across restarts).
    property bool caffeine: false
    // Caffeine until a time (ms since epoch, 0 = until turned off).
    property real caffeineUntil: 0
    onCaffeineChanged: if (!caffeine) caffeineUntil = 0

    // `minutes` 0: until turned off.
    property int caffeineMinutes: 0
    function setCaffeine(on: bool, minutes: int): void {
        caffeineMinutes = on ? minutes : 0;
        caffeineUntil = on && minutes > 0 ? Date.now() + minutes * 60000 : 0;
        caffeine = on;
    }

    Timer {
        running: root.caffeine && root.caffeineUntil > 0
        interval: 15000
        repeat: true
        triggeredOnStart: true
        onTriggered: if (Date.now() >= root.caffeineUntil) root.caffeine = false
    }
    readonly property string inhibitedBy: caffeine ? "caffeine" : inhibitWhenAudio && playing ? "audio" : inhibitWhenCharging && onPower ? "charging" : ""
    readonly property bool active: enabled && !inhibitedBy

    function screens(on: bool): void {
        Lock.screens(on);
    }

    IdleMonitor {
        enabled: root.active && root.lockAfter > 0
        timeout: Math.max(1, root.lockAfter)
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Lock.lockQuiet("idle")
    }

    IdleMonitor {
        enabled: root.active && root.screenOffAfter > 0
        timeout: Math.max(1, root.screenOffAfter)
        respectInhibitors: true
        onIsIdleChanged: root.screens(!isIdle)
    }

    // Once locked, screens go off sooner (the lock itself is no reason to
    // keep them lit). Not held by audio: the session is locked.
    IdleMonitor {
        enabled: root.enabled && Lock.locked && root.lockedScreenOffAfter > 0
        timeout: Math.max(1, root.lockedScreenOffAfter)
        respectInhibitors: true
        onIsIdleChanged: root.screens(!isIdle)
    }

    IdleMonitor {
        enabled: root.active && root.suspendAfter > 0
        timeout: Math.max(1, root.suspendAfter)
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Lock.suspend()
    }
}
