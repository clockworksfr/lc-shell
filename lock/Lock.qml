pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.services

// Lock state and authentication (PAM).
//
// Safety: if the shell dies while locked, the compositor keeps the session
// locked (red screen). Hyprland's misc.allow_session_lock_restore lets a
// restarted shell (or hyprlock, kept as a fallback) take over.
//
// Settings: "lock": { "pamService": "hyprlock", "beforeSleep": true }
Singleton {
    id: root

    readonly property var config: Config.data.lock ?? {}

    property bool locked: false
    // Preview window open: the same UI and PAM check, nothing locked.
    property bool previewing: false

    readonly property bool checking: pam.active
    // "" | "failed" | "error" | "accepted" (preview only)
    property string status
    property bool forPreview: false
    property string pendingPassword

    // Unlocked: hold the sleep delay again for the next suspend.
    onLockedChanged: if (!locked) sleepDelay.running = config.beforeSleep ?? true

    function lock(): void {
        status = "";
        locked = true;
    }

    function submit(password: string, preview: bool): void {
        if (pam.active || !password)
            return;
        pendingPassword = password;
        forPreview = preview;
        status = "";
        pam.start();
    }

    PamContext {
        id: pam

        config: root.config.pamService ?? "hyprlock"
        user: Quickshell.env("USER") ?? ""

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
            }
        }

        onError: error => {
            root.pendingPassword = "";
            root.status = "error";
            console.warn(`lock: PAM error ${PamError.toString(error)}`);
        }
    }

    // --- logind: lock-session, and lock before sleep ---

    Connections {
        target: Logind

        function onLockRequested(): void {
            root.lock();
        }
        function onUnlockRequested(): void {
            root.locked = false;
        }
        function onPrepareForSleep(sleeping: bool): void {
            if (sleeping && (root.config.beforeSleep ?? true))
                root.lock();
            else if (!sleeping)
                sleepDelay.running = root.config.beforeSleep ?? true;
        }
    }

    // Holds a "delay" inhibitor so suspend waits until the lock is shown;
    // released (process stopped) once locked, taken again after resume.
    Process {
        id: sleepDelay
        running: root.config.beforeSleep ?? true
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=lc-shell", "--why=Lock the screen before sleep", "sleep", "infinity"]
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
