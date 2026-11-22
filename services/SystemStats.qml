pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and GPU load, plus temperatures, sampled every 2 s while
// something uses them (`refCount`, so idle screens cost nothing).
Singleton {
    id: root

    property int refCount: 0

    property real cpu: 0 // 0..1
    property real memory: 0 // 0..1
    property real memoryUsedGiB: 0
    property real memoryTotalGiB: 0
    property real cpuTemp: 0 // °C
    // [{ card, busy (0..1), temp (°C) }]
    property var gpus: []

    property var lastCpu: null

    Timer {
        interval: 2000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            sensors.running = true;
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const fields = text().split("\n")[0].split(/\s+/).slice(1).map(Number);
            const idle = fields[3] + fields[4];
            const total = fields.reduce((a, b) => a + b, 0);
            if (root.lastCpu) {
                const dTotal = total - root.lastCpu.total;
                root.cpu = dTotal > 0 ? 1 - (idle - root.lastCpu.idle) / dTotal : 0;
            }
            root.lastCpu = { idle, total };
        }
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const value = key => parseInt((text().match(new RegExp(`^${key}:\\s+(\\d+)`, "m")) ?? [])[1] ?? "0");
            const total = value("MemTotal");
            const available = value("MemAvailable");
            root.memoryTotalGiB = total / 1048576;
            root.memoryUsedGiB = (total - available) / 1048576;
            root.memory = total > 0 ? 1 - available / total : 0;
        }
    }

    // One shell call for the sysfs files whose names vary (cards, hwmon).
    // Output lines: "gpu <card> <busy%> <temp milli°C>" and "cpu <temp milli°C>".
    Process {
        id: sensors
        command: ["sh", "-c", `
            for d in /sys/class/drm/card[0-9]*/device; do
                [ -r "$d/gpu_busy_percent" ] || continue
                t=$(cat "$d"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
                echo "gpu $(basename "$(dirname "$d")") $(cat "$d/gpu_busy_percent") \${t:-0}"
            done
            for h in /sys/class/hwmon/hwmon*; do
                case "$(cat "$h/name")" in k10temp|coretemp|zenpower) echo "cpu $(cat "$h/temp1_input")"; break;; esac
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const gpus = [];
                for (const line of text.split("\n")) {
                    const f = line.trim().split(" ");
                    if (f[0] === "gpu")
                        gpus.push({ card: f[1], busy: Number(f[2]) / 100, temp: Number(f[3]) / 1000 });
                    else if (f[0] === "cpu")
                        root.cpuTemp = Number(f[1]) / 1000;
                }
                root.gpus = gpus;
            }
        }
    }
}
