pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pam
import qs.services

// Lock state and authentication (PAM).
//
// Safety: if the shell dies while locked, the compositor keeps the session
// locked (red screen). Hyprland's misc.allow_session_lock_restore lets a
// restarted shell (or hyprlock, kept as a fallback) take over.
//
// Settings ("lock"):
//   shortcut        keys of the lock shortcut, applied to Hyprland by the
//                   shell ("" = none); replaces any bind on the same keys
//   afterLock       "screensOff" | "suspend" | "none": a few seconds after a
//                   lock asked for (shortcut, IPC), unless the keyboard or
//                   mouse is used on the lock screen meanwhile
//   afterLockDelay  seconds
//   beforeSleep     lock before suspend (logind)
//   pamService      PAM service checking the password
//   avatar, power, battery, blur   what the lock panel shows
Singleton {
    id: root

    readonly property var config: Config.data.lock ?? {}
    readonly property string shortcut: config.shortcut ?? "SUPER + Escape"
    readonly property string afterLock: ["screensOff", "suspend", "none"].includes(config.afterLock) ? config.afterLock : "screensOff"
    readonly property int afterLockDelay: Math.max(1, config.afterLockDelay ?? 5)
    readonly property bool beforeSleep: config.beforeSleep ?? true

    property bool locked: false
    // Preview window open: the same UI and PAM check, nothing locked.
    property bool previewing: false

    readonly property bool checking: pam.active
    // "" | "failed" | "error" | "accepted" (preview only)
    property string status
    property bool forPreview: false
    property string pendingPassword
    // Failed attempts since the lock (the panel shakes on each).
    property int failures: 0

    // Seconds left before the after-lock action, 0 = none pending.
    property int countdown: 0
    property bool capsLock: false

    readonly property string user: Quickshell.env("USER") ?? ""
    // Test harnesses (LC_LOCK_BIND=0): no Hyprland bind, no sleep inhibitor,
    // no relock after a crash.
    readonly property bool harness: Quickshell.env("LC_LOCK_BIND") === "0"
    // "First Last" from the passwd entry, else the login.
    property string fullName: user

    // While locked, a marker in the runtime dir holding Hyprland's instance
    // signature: a shell restarted after a crash in the same Hyprland finds
    // it and locks again (with misc.allow_session_lock_restore it takes the
    // session lock back). Removed on unlock; ignored from another Hyprland
    // instance (a new login after a crash).
    readonly property string marker: `${Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"}/lc-shell-locked`
    readonly property string instance: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") ?? ""

    // Unlocked: hold the sleep delay again for the next suspend.
    onLockedChanged: {
        if (!locked) {
            sleepDelay.running = beforeSleep;
            cancelAfterLock();
            console.info("lock: unlocked");
            if (!harness)
                Quickshell.execDetached(["rm", "-f", marker]);
        } else {
            failures = 0;
            checkCaps();
            if (!harness)
                Quickshell.execDetached(["sh", "-c", 'umask 077 && printf "%s" "$1" > "$2"', "sh", instance, marker]);
        }
    }

    Process {
        running: !root.harness
        command: ["sh", "-c", '[ -f "$1" ] && [ "$(cat "$1")" = "$2" ]', "sh", root.marker, root.instance]
        onExited: code => {
            if (code === 0 && !root.locked) {
                console.warn("lock: the shell stopped while locked; locking again");
                root.lockQuiet("relock");
            } else if (code !== 0) {
                Quickshell.execDetached(["rm", "-f", root.marker]);
            }
        }
    }

    // A lock asked for by the user (shortcut, IPC): the after-lock action
    // follows.
    function lock(): void {
        console.info("lock: locked (shortcut / IPC)");
        status = "";
        locked = true;
        if (afterLock !== "none") {
            countdown = afterLockDelay;
            tick.restart();
        }
    }

    // A lock from idle or logind: no after-lock action (idle has its own
    // delays; logind is about to suspend anyway).
    function lockQuiet(reason: string): void {
        if (!locked)
            console.info(`lock: locked (${reason || "idle / logind"})`);
        status = "";
        locked = true;
    }

    // Input on the lock screen: the user is there, keep the screens on.
    function cancelAfterLock(): void {
        countdown = 0;
        tick.stop();
    }

    function submit(password: string, preview: bool): void {
        if (pam.active || !password)
            return;
        cancelAfterLock();
        pendingPassword = password;
        forPreview = preview;
        status = "";
        pam.start();
    }

    function screens(on: bool): void {
        Hyprland.dispatch(`hl.dsp.dpms({ action = "${on ? "on" : "off"}" })`);
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }
    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }
    function powerOff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function checkCaps(): void {
        caps.running = false;
        caps.running = true;
    }

    Timer {
        id: tick
        interval: 1000
        repeat: true
        onTriggered: {
            if (!root.locked) {
                root.cancelAfterLock();
                return;
            }
            root.countdown -= 1;
            if (root.countdown > 0)
                return;
            stop();
            if (root.afterLock === "screensOff")
                root.screens(false);
            else if (root.afterLock === "suspend")
                root.suspend();
        }
    }

    PamContext {
        id: pam

        config: root.config.pamService ?? "hyprlock"
        user: root.user

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.pendingPassword);
            root.pendingPassword = "";
        }

        onCompleted: result => {
            root.pendingPassword = "";
            if (result === PamResult.Success) {
                if (root.forPreview)
                    root.status = "accepted";
                else
                    root.locked = false;
            } else {
                root.status = result === PamResult.Failed || result === PamResult.MaxTries ? "failed" : "error";
                root.failures += 1;
            }
        }

        onError: error => {
            root.pendingPassword = "";
            root.status = "error";
            root.failures += 1;
            console.warn(`lock: PAM error ${PamError.toString(error)}`);
        }
    }

    // Caps Lock of the main keyboard (Hyprland knows it; Qt doesn't).
    Process {
        id: caps
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const keyboards = JSON.parse(text).keyboards ?? [];
                    const main = keyboards.find(k => k.main) ?? keyboards[0];
                    root.capsLock = !!main?.capsLock;
                } catch (e) {
                    root.capsLock = false;
                }
            }
        }
    }

    Process {
        running: !!root.user
        command: ["getent", "passwd", root.user]
        stdout: StdioCollector {
            onStreamFinished: {
                const gecos = (text.split(":")[4] ?? "").split(",")[0].trim();
                if (gecos)
                    root.fullName = gecos;
            }
        }
    }

    // --- The lock shortcut, applied to Hyprland ---
    // hl.unbind drops every bind on the keys (the config's own one too), then
    // the shell's bind: the shell's lock over IPC, or hyprlock when the shell
    // doesn't answer (stopped, crashed), so the keys always lock.
    // Applied at start, when the setting changes, after config reloads.
    readonly property string fallbackCommand: "qs -c lc ipc call lock lock || pidof hyprlock || hyprlock"
    property string appliedShortcut

    function applyShortcut(): void {
        if (harness)
            return;
        const keys = shortcut.trim().replace(/"/g, "");
        const lua = [];
        if (appliedShortcut && appliedShortcut !== keys)
            lua.push(`hl.unbind("${appliedShortcut}")`);
        if (keys)
            lua.push(`hl.unbind("${keys}")`, `hl.bind("${keys}", hl.dsp.exec_cmd("${fallbackCommand}"), { desc = "Verrouiller (lc-shell, sinon hyprlock)" })`);
        appliedShortcut = keys;
        if (!lua.length)
            return;
        bind.command = ["hyprctl", "eval", lua.join("; ")];
        bind.running = true;
    }

    onShortcutChanged: bindLater.restart()
    Component.onCompleted: bindLater.restart()

    Timer {
        id: bindLater
        interval: 200
        onTriggered: root.applyShortcut()
    }

    Process {
        id: bind
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() && text.trim() !== "ok") console.warn(`lock: shortcut: ${text.trim()}`)
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded") {
                // The config's binds are back: ours goes over them again.
                root.appliedShortcut = "";
                bindLater.restart();
            }
        }
    }

    // --- logind: lock-session, and lock before sleep ---

    Connections {
        target: Logind

        function onLockRequested(): void {
            root.lockQuiet("logind lock-session");
        }
        function onUnlockRequested(): void {
            console.info("lock: unlock asked by logind");
            root.locked = false;
        }
        function onPrepareForSleep(sleeping: bool): void {
            if (sleeping && root.beforeSleep) {
                root.cancelAfterLock();
                root.lockQuiet("before sleep");
            } else if (!sleeping) {
                sleepDelay.running = root.beforeSleep;
            }
        }
    }

    // Holds a "delay" inhibitor so suspend waits until the lock is shown;
    // released (process stopped) once locked, taken again after resume.
    // The inhibitor (and its sleep) die with the shell (pdeathsig): a shell
    // killed or restarted leaves none behind. Stale ones (older shells) are
    // stopped at start, before ours.
    Process {
        id: sleepDelay
        running: root.beforeSleep && root.swept
        command: ["setpriv", "--pdeathsig", "TERM", "systemd-inhibit", "--what=sleep", "--mode=delay", "--who=lc-shell", "--why=Lock the screen before sleep", "setpriv", "--pdeathsig", "TERM", "sleep", "infinity"]
    }

    property bool swept: false

    Process {
        running: !root.harness
        command: ["sh", "-c", "for p in $(pgrep -f '^[^ ]*systemd-inhibit --what=sleep --mode=delay --who=lc-shell '); do pkill -P \"$p\"; kill \"$p\"; done; true"]
        onExited: root.swept = true
    }

    function surfacesShown(): void {
        // Let the lock frame reach the screen, then let suspend proceed.
        release.restart();
    }

    Timer {
        id: release
        interval: 300
        onTriggered: sleepDelay.running = false
    }
}
