pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Audio spectrum of what's playing (cava, PipeWire input): `bars` bands,
// 0..1, about 30 updates per second. Runs only while something uses it
// (refCount), and not at all when cava is missing.
Singleton {
    id: root

    property int refCount: 0
    readonly property int bands: 32
    property var values: []
    property string lastLine
    // Bumped with each new frame; resampled(count) caches per frame.
    property int frame: 0
    property var cache: ({})

    // `count` values from the bands (max of each group), once a frame.
    function resampled(count: int): var {
        const hit = cache[count];
        if (hit && hit.frame === frame)
            return hit.levels;
        const v = values;
        const out = new Array(count);
        for (let i = 0; i < count; i++) {
            if (!v.length) {
                out[i] = 0;
                continue;
            }
            const a = Math.floor(i * v.length / count);
            const b = Math.max(a + 1, Math.floor((i + 1) * v.length / count));
            let m = 0;
            for (let j = a; j < b; j++)
                m = Math.max(m, v[j] ?? 0);
            out[i] = m;
        }
        cache[count] = { frame: frame, levels: out };
        return out;
    }
    readonly property bool active: refCount > 0

    readonly property string configPath: Quickshell.cachePath("cava.conf")

    FileView {
        id: config
        path: root.configPath
        printErrors: false
    }

    Component.onCompleted: config.setText([
        "[general]",
        `bars = ${root.bands}`,
        "framerate = 30",
        "autosens = 1",
        "[input]",
        "method = pipewire",
        "source = auto",
        "[output]",
        "method = raw",
        "raw_target = /dev/stdout",
        "data_format = ascii",
        "ascii_max_range = 100",
        "bar_delimiter = 59",
        "frame_delimiter = 10",
        "[smoothing]",
        "noise_reduction = 60",
        ""
    ].join("\n"))

    Process {
        id: cava
        running: root.active
        command: ["cava", "-p", root.configPath]
        stdout: SplitParser {
            onRead: line => {
                // Identical frames (silence) change nothing: skipped.
                if (line === root.lastLine)
                    return;
                root.lastLine = line;
                const parts = line.split(";");
                const out = [];
                for (let i = 0; i < parts.length; i++)
                    if (parts[i] !== "")
                        out.push(Math.min(1, Number(parts[i]) / 100));
                if (out.length) {
                    root.values = out;
                    root.frame++;
                }
            }
        }
        onRunningChanged: if (!running) {
            root.values = [];
            root.frame++;
            root.lastLine = "";
        }
    }
}
