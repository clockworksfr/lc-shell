import QtQuick
import Quickshell
import Quickshell.Io

// Brightness of one screen. Created by the Brightness singleton.
// - Internal panel (eDP-*): kernel backlight, set with brightnessctl and
//   watched in sysfs, so changes from the key binds are seen too.
// - External screens: DDC/CI through ddcutil (slow, so writes are coalesced).
Scope {
    id: root

    required property ShellScreen modelData
    property var ddcBuses: ({})

    readonly property string name: modelData.name
    readonly property bool internal: name.startsWith("eDP")
    readonly property int bus: ddcBuses[name] ?? -1
    readonly property bool available: internal ? backlightMax > 0 : ddcMax > 0

    property real brightness: 0 // 0..1

    property string backlightDevice
    property bool backlightLoaded: false
    property int backlightMax: 0
    property int ddcMax: 0
    property int pendingDdc: -1

    // Brightness changed (by the shell, or by brightnessctl for the backlight).
    signal touched

    function setBrightness(value: real): void {
        if (!available)
            return;
        value = Math.max(0, Math.min(1, value));
        // Still signal at the limits, so the OSD shows that 0/100 % is reached.
        const changed = Math.abs(value - brightness) >= 0.001;
        brightness = value;
        touched();
        if (!changed)
            return;

        if (internal) {
            backlightSet.command = ["brightnessctl", "-q", "-d", backlightDevice, "set", `${Math.round(value * 100)}%`];
            backlightSet.running = true;
        } else {
            pendingDdc = Math.round(value * ddcMax);
            flushDdc();
        }
    }

    function flushDdc(): void {
        if (pendingDdc < 0 || ddcSet.running)
            return;
        ddcSet.command = ["ddcutil", "--bus", `${bus}`, "--noverify", "setvcp", "10", `${pendingDdc}`];
        pendingDdc = -1;
        ddcSet.running = true;
    }

    // --- Internal backlight ---

    Process {
        running: root.internal
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        // Format: device,class,current,percent,max
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length < 5)
                    return;
                root.backlightDevice = fields[0];
                root.backlightMax = parseInt(fields[4]);
            }
        }
    }

    FileView {
        path: root.backlightDevice ? `/sys/class/backlight/${root.backlightDevice}/brightness` : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = parseInt(text()) / root.backlightMax;
            if (isNaN(value) || Math.abs(value - root.brightness) < 0.001)
                return;
            root.brightness = value;
            // The first read is the initial state, not a change.
            if (root.backlightLoaded)
                root.touched();
            root.backlightLoaded = true;
        }
    }

    Process {
        id: backlightSet
    }

    // --- DDC/CI ---

    Process {
        running: !root.internal && root.bus >= 0
        command: ["ddcutil", "--bus", `${root.bus}`, "--brief", "getvcp", "10"]
        // Format: VCP 10 C <current> <max>
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(/\s+/);
                if (fields.length < 5 || fields[0] !== "VCP")
                    return;
                root.ddcMax = parseInt(fields[4]);
                root.brightness = parseInt(fields[3]) / root.ddcMax;
            }
        }
    }

    Process {
        id: ddcSet
        onExited: root.flushDdc()
    }
}
