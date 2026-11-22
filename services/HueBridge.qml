pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Philips Hue through `huectl` (~/.local/bin, JSON out): rooms (groups with
// a class and lights), their lights and scenes; actions applied to the model
// at once (optimistic), then read back from the bridge 400 ms later.
// Refreshed every 10 s while something shows it (refCount).
Singleton {
    id: root

    // ~/.local/bin isn't in the shell's PATH.
    readonly property string bin: `${Quickshell.env("HOME")}/.local/bin/huectl`

    property int refCount: 0
    property bool available: true
    property bool loading: false
    property bool loaded: false
    property string lastError: ""

    // [{ id, name, cls, on, brightness, color, scenes: [{ id, name }], lights: [ids] }]
    property var rooms: []
    // id → { id, name, on, reachable, brightness, color }
    property var lights: ({})
    // Last scene started per room (the bridge doesn't say), id → scene id.
    property var activeScene: ({})

    readonly property int roomsOn: rooms.filter(r => r.on).length

    readonly property var favorites: [
        { name: "warm", color: "#FFB46B" },
        { name: "neutral", color: "#FFE9D2" },
        { name: "cold", color: "#D6ECFF" },
        { name: "ember", color: "#FF5A3D" },
        { name: "violet", color: "#8A6BFF" },
        { name: "lagoon", color: "#3DD6FF" }
    ]

    function roomIcon(cls: string): string {
        return ({ LivingRoom: "weekend", Lounge: "weekend", Bedroom: "bed", Office: "desk", Kitchen: "kitchen", Tv: "tv" })[cls] ?? "lightbulb";
    }

    function room(id: string): var {
        return rooms.find(r => r.id === id) ?? null;
    }

    function refresh(): void {
        if (reader.running)
            return;
        loading = true;
        reader.running = true;
    }

    function parse(text: string): void {
        const d = JSON.parse(text);
        const map = {};
        for (const l of d.lights ?? [])
            map[l.id] = { id: l.id, name: l.name, on: !!l.on, reachable: l.reachable !== false, brightness: l.brightness ?? 0, color: l.color ?? "" };
        lights = map;
        rooms = (d.groups ?? []).filter(g => g.class && (g.lights ?? []).length > 0).map(g => ({
            id: g.id,
            name: g.name,
            cls: g.class,
            on: !!g.any_on,
            brightness: g.brightness ?? 0,
            color: g.color ?? "",
            scenes: (g.scenes ?? []).map(s => ({ id: s.id, name: s.name })).sort((a, b) => a.name.localeCompare(b.name)),
            lights: g.lights
        }));
        loaded = true;
    }

    // One process per action (no blocking queue); a read 400 ms after.
    function run(args: var): void {
        const p = actionComponent.createObject(root, { command: [bin, ...args] });
        p.running = true;
        readBack.restart();
    }

    function patchRoom(id: string, change: var): void {
        rooms = rooms.map(r => r.id === id ? Object.assign({}, r, change) : r);
    }

    function patchLight(id: string, change: var): void {
        const next = Object.assign({}, lights);
        if (next[id])
            next[id] = Object.assign({}, next[id], change);
        lights = next;
    }

    function forgetScene(id: string): void {
        if (activeScene[id] === undefined)
            return;
        const next = Object.assign({}, activeScene);
        delete next[id];
        activeScene = next;
    }

    function toggleRoom(id: string): void {
        const r = room(id);
        if (!r)
            return;
        patchRoom(id, { on: !r.on });
        run(["group", id, r.on ? "off" : "on"]);
    }

    function setRoomBrightness(id: string, pct: int): void {
        patchRoom(id, { on: true, brightness: pct });
        forgetScene(id);
        throttle.send(["group", id, "bri", `${pct}`]);
    }

    function setRoomColor(id: string, hex: string): void {
        patchRoom(id, { on: true, color: hex });
        forgetScene(id);
        throttle.send(["group", id, "color", hex]);
    }

    function setRoomWhite(id: string, kelvin: int): void {
        patchRoom(id, { on: true, color: kelvinColor(kelvin) });
        forgetScene(id);
        throttle.send(["group", id, "ct", `${kelvin}`]);
    }

    function allOff(): void {
        for (const r of rooms)
            if (r.on) {
                patchRoom(r.id, { on: false });
                run(["group", r.id, "off"]);
            }
    }

    function toggleLight(id: string): void {
        const l = lights[id];
        if (!l || !l.reachable)
            return;
        patchLight(id, { on: !l.on });
        run(["light", id, l.on ? "off" : "on"]);
    }

    function setLightBrightness(id: string, pct: int): void {
        patchLight(id, { on: true, brightness: pct });
        throttle.send(["light", id, "bri", `${pct}`]);
    }

    function setLightColor(id: string, hex: string): void {
        patchLight(id, { on: true, color: hex });
        throttle.send(["light", id, "color", hex]);
    }

    function setLightWhite(id: string, kelvin: int): void {
        patchLight(id, { on: true, color: kelvinColor(kelvin) });
        throttle.send(["light", id, "ct", `${kelvin}`]);
    }

    function startScene(roomId: string, sceneId: string): void {
        const next = Object.assign({}, activeScene);
        next[roomId] = sceneId;
        activeScene = next;
        patchRoom(roomId, { on: true });
        run(["scene", sceneId]);
    }

    // Approximate color of a white temperature (Tanner Helland), for the
    // swatches; the bulbs get the real `ct`.
    function kelvinColor(kelvin: int): string {
        const t = kelvin / 100;
        const clamp = v => Math.max(0, Math.min(255, Math.round(v)));
        const r = t <= 66 ? 255 : clamp(329.698727446 * Math.pow(t - 60, -0.1332047592));
        const g = t <= 66 ? clamp(99.4708025861 * Math.log(t) - 161.1195681661) : clamp(288.1221695283 * Math.pow(t - 60, -0.0755148492));
        const b = t >= 66 ? 255 : t <= 19 ? 0 : clamp(138.5177312231 * Math.log(t - 10) - 305.0447927307);
        const hex = v => v.toString(16).padStart(2, "0");
        return `#${hex(r)}${hex(g)}${hex(b)}`;
    }

    // Sliders and color drags: at most one command every 150 ms, the last
    // one always sent.
    QtObject {
        id: throttle

        property var pending: null

        function send(args: var): void {
            pending = args;
            if (!timer.running) {
                root.run(pending);
                pending = null;
                timer.start();
            }
        }

        readonly property Timer timer: Timer {
            interval: 150
            onTriggered: {
                if (throttle.pending) {
                    root.run(throttle.pending);
                    throttle.pending = null;
                    start();
                }
            }
        }
    }

    Component {
        id: actionComponent

        Process {
            stderr: StdioCollector {
                onStreamFinished: if (text.trim()) root.lastError = text.trim()
            }
            onExited: destroy()
        }
    }

    Process {
        id: reader
        command: [root.bin, "state"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                try {
                    root.parse(text);
                    root.lastError = "";
                } catch (e) {
                    root.lastError = "unreadable";
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: if (text.trim()) root.lastError = text.trim()
        }
        onExited: code => {
            root.loading = false;
            // 127: not found (no binary).
            if (code === 127)
                root.available = false;
        }
    }

    // The bridge takes a moment to reflect a change.
    Timer {
        id: readBack
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        running: root.refCount > 0
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // The binary is there?
    Process {
        running: true
        command: ["test", "-x", root.bin]
        onExited: code => root.available = code === 0
    }
}
