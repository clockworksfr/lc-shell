pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// logind signals, through `gdbus monitor` on the system bus:
//   lockRequested / unlockRequested   (loginctl lock-session / unlock-session)
//   prepareForSleep(sleeping)          (before suspend: true, after: false)
// Only this session's Lock/Unlock are taken (XDG_SESSION_ID).
Singleton {
    id: root

    signal lockRequested
    signal unlockRequested
    signal prepareForSleep(bool sleeping)

    readonly property string sessionId: Quickshell.env("XDG_SESSION_ID") ?? ""
    // sd-bus object path escaping: non-alphanumerics, and a leading digit,
    // become _XX (hex).
    readonly property string sessionPath: sessionId ? "/org/freedesktop/login1/session/" + sessionId.split("").map((c, i) => /[A-Za-z0-9]/.test(c) && !(i === 0 && /[0-9]/.test(c)) ? c : "_" + c.charCodeAt(0).toString(16).padStart(2, "0")).join("") : ""

    Process {
        id: monitor
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1"]
        stdout: SplitParser {
            onRead: line => {
                // Unknown session: take Lock (safe), never Unlock (it could be
                // another session's).
                const forUs = !!root.sessionPath && line.startsWith(root.sessionPath + ":");
                if (line.includes("org.freedesktop.login1.Session.Lock") && (forUs || !root.sessionPath))
                    root.lockRequested();
                else if (line.includes("org.freedesktop.login1.Session.Unlock") && forUs)
                    root.unlockRequested();
                else if (line.includes("org.freedesktop.login1.Manager.PrepareForSleep"))
                    root.prepareForSleep(line.includes("(true"));
            }
        }
        // gdbus shouldn't exit; if it does (bus restart), start it again.
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: monitor.running = true
    }
}
