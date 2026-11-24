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
    property real diskTemp: 0 // °C, NVMe
    property real ramTemp: 0 // °C, hottest memory module (SPD sensor)
    // [{ card, busy (0..1), temp (°C) }]
    property var gpus: []

    property var lastCpu: null
    // Each core's load (0..1).
    property var cores: []
    property var lastCores: []
    // The last minute (30 samples, 2 s apart), 0..1: CPU, dedicated (or
    // first) GPU, memory.
    property var cpuHistory: []
    property var gpuHistory: []
    property var memoryHistory: []

    Timer {
        interval: 2000
        running: root.refCount > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            meminfo.reload();
            sensors.running = true;
            const gpu = root.gpus.find(g => !g.integrated) ?? root.gpus[0];
            root.cpuHistory = [...root.cpuHistory, root.cpu].slice(-30);
            root.gpuHistory = [...root.gpuHistory, gpu?.busy ?? 0].slice(-30);
            root.memoryHistory = [...root.memoryHistory, root.memory].slice(-30);
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const lines = text().split("\n");
            const parse = line => {
                const fields = line.split(/\s+/).slice(1).map(Number);
                return { idle: fields[3] + fields[4], total: fields.reduce((a, b) => a + b, 0) };
            };
            const busy = (now, last) => {
                const dTotal = now.total - (last?.total ?? 0);
                return last && dTotal > 0 ? 1 - (now.idle - last.idle) / dTotal : 0;
            };
            const all = parse(lines[0]);
            if (root.lastCpu)
                root.cpu = busy(all, root.lastCpu);
            root.lastCpu = all;
            // Per core (cpu0, cpu1…): Modulaire's ladders.
            const cores = lines.filter(l => /^cpu\d+ /.test(l)).map(parse);
            const last = root.lastCores;
            root.cores = cores.map((c, i) => busy(c, last[i]));
            root.lastCores = cores;
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
    // Output lines: "gpu <card> <busy%> <temp milli°C> <kind>", "cpu", "disk", "ram" <temp milli°C>.
    Process {
        id: sensors
        command: ["sh", "-c", `
            for d in /sys/class/drm/card[0-9]*/device; do
                [ -r "$d/gpu_busy_percent" ] || continue
                t=$(cat "$d"/hwmon/hwmon*/temp1_input 2>/dev/null | head -n1)
                c=$(basename "$(dirname "$d")")
                # Integrated = the one driving the laptop panel.
                k=discrete; ls -d /sys/class/drm/$c-eDP-* >/dev/null 2>&1 && k=integrated
                echo "gpu $c $(cat "$d/gpu_busy_percent") \${t:-0} $k"
            done
            for h in /sys/class/hwmon/hwmon*; do
                case "$(cat "$h/name")" in
                    k10temp|coretemp|zenpower) echo "cpu $(cat "$h/temp1_input")";;
                    nvme) echo "disk $(cat "$h/temp1_input")";;
                    spd5118|jc42) echo "ram $(cat "$h/temp1_input")";;
                esac
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const gpus = [];
                let disk = 0, ram = 0;
                for (const line of text.split("\n")) {
                    const f = line.trim().split(" ");
                    if (f[0] === "gpu")
                        gpus.push({ card: f[1], busy: Number(f[2]) / 100, temp: Number(f[3]) / 1000, integrated: f[4] === "integrated" });
                    else if (f[0] === "cpu")
                        root.cpuTemp = Number(f[1]) / 1000;
                    else if (f[0] === "disk")
                        disk = Math.max(disk, Number(f[1]) / 1000);
                    else if (f[0] === "ram")
                        ram = Math.max(ram, Number(f[1]) / 1000);
                }
                root.gpus = gpus;
                root.diskTemp = disk;
                root.ramTemp = ram;
            }
        }
    }
}
