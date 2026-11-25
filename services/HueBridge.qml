pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Philips Hue, talking to the bridge directly (local HTTP, API v1): rooms
// (groups with a class and lights), their lights and scenes; actions
// applied to the model at once (optimistic), then read back from the
// bridge 400 ms later. Refreshed every 10 s while something shows it
// (refCount).
//
// Pairing (Settings › Lights): discovery through discovery.meethue.com or
// an address typed by hand, then a user registered while the bridge's link
// button is pressed. Credentials live in their own file,
// $XDG_CONFIG_HOME/lc/hue.json (mode 600), never in settings.json; on
// first run, those of huectl (~/.config/huectl/config.json) are taken over
// if present, as the bridge limits the number of registered users.
Singleton {
    id: root

    property int refCount: 0
    // A paired bridge (address and user known).
    readonly property bool available: bridgeIp !== "" && username !== ""
    property bool loading: false
    property bool loaded: false
    // "" | "unreachable" | "unauthorized" | "unreadable"
    property string lastError: ""

    // [{ id, name, cls, on, brightness, color, scenes: [{ id, name }], lights: [ids] }]
    property var rooms: []
    // id → { id, name, on, reachable, brightness, color }
    property var lights: ({})
    // The color panel's target: { kind: "room" | "light", id, name, screen }.
    property var picker: null

    // The lights panel on a screen (the drawer where the bar has the
    // widget, else a centered panel: HueFallback).
    function openPanel(screenName: string): void {
        ShellState.panelRequested("lights", screenName);
    }

    // Last scene started per room (the bridge doesn't say), id → scene id.
    property var activeScene: ({})

    readonly property int roomsOn: rooms.filter(r => r.on).length

    // A bridge just paired (or loaded at startup): its state at once.
    onAvailableChanged: if (available)
        refresh()

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

    // ── Credentials ─────────────────────────────────────────────────────

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
    readonly property string credentialsPath: `${configHome}/lc/hue.json`
    property string bridgeIp: ""
    property string username: ""
    // huectl's credentials are taken over once, at startup only (not after
    // "Forget").
    property bool importTried: false

    FileView {
        id: credentials
        path: root.credentialsPath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const c = JSON.parse(text());
                root.bridgeIp = c.bridge_ip ?? "";
                root.username = c.username ?? "";
            } catch (e) {
                root.bridgeIp = "";
                root.username = "";
            }
            root.importTried = true;
        }
        onLoadFailed: {
            root.bridgeIp = "";
            root.username = "";
            if (!root.importTried) {
                root.importTried = true;
                legacy.path = `${root.configHome}/huectl/config.json`;
            }
        }
    }

    FileView {
        id: legacy
        printErrors: false
        onLoaded: {
            try {
                const c = JSON.parse(text());
                if (c.bridge_ip && c.username)
                    root.saveCredentials(c.bridge_ip, c.username);
            } catch (e) {}
        }
    }

    // Written through a shell with umask 077 (the user is a secret), from
    // stdin (never on a command line, which other users can read).
    function saveCredentials(ip: string, user: string): void {
        bridgeIp = ip;
        username = user;
        writer.payload = JSON.stringify({ bridge_ip: ip, username: user }, null, 2) + "\n";
        writer.running = true;
    }

    Process {
        id: writer
        property string payload
        stdinEnabled: true
        command: ["sh", "-c", 'umask 077 && mkdir -p "$(dirname "$1")" && cat > "$1.tmp" && chmod 600 "$1.tmp" && mv "$1.tmp" "$1"', "sh", root.credentialsPath]
        onStarted: {
            write(payload);
            payload = "";
            stdinEnabled = false;
        }
        onExited: {
            stdinEnabled = true;
            credentials.reload();
            root.refresh();
        }
    }

    function forget(): void {
        bridgeIp = "";
        username = "";
        rooms = [];
        lights = {};
        loaded = false;
        lastError = "";
        remover.running = true;
    }

    Process {
        id: remover
        command: ["rm", "-f", root.credentialsPath]
    }

    // ── HTTP ────────────────────────────────────────────────────────────

    // cb(status, json or null); 0 = no answer (timeout, refused).
    function request(method: string, url: string, body: var, cb: var, timeout: int): void {
        const x = new XMLHttpRequest();
        const timer = timerComponent.createObject(root, { interval: timeout || 5000 });
        let done = false;
        const finish = (status, data) => {
            if (done)
                return;
            done = true;
            timer.destroy();
            if (cb)
                cb(status, data);
        };
        timer.triggered.connect(() => {
            x.abort();
            finish(0, null);
        });
        x.onreadystatechange = () => {
            if (x.readyState !== XMLHttpRequest.DONE)
                return;
            let data = null;
            try {
                data = JSON.parse(x.responseText);
            } catch (e) {}
            finish(x.status, data);
        };
        x.open(method, url);
        if (body !== null && body !== undefined) {
            x.setRequestHeader("Content-Type", "application/json");
            x.send(JSON.stringify(body));
        } else {
            x.send();
        }
        timer.start();
    }

    Component {
        id: timerComponent
        Timer {}
    }

    readonly property string base: available ? `http://${bridgeIp}/api/${username}` : ""

    // ── State ───────────────────────────────────────────────────────────

    // scene id → its group ("0" for scenes without one), for startScene.
    property var sceneGroups: ({})

    function refresh(): void {
        if (!available || loading)
            return;
        loading = true;
        request("GET", base, null, (status, d) => {
            root.loading = false;
            if (status === 0 || !d) {
                root.lastError = status === 0 ? "unreachable" : "unreadable";
                return;
            }
            if (Array.isArray(d)) {
                // [{ error: { type: 1, "unauthorized user" } }]
                root.lastError = d[0]?.error?.type === 1 ? "unauthorized" : "unreadable";
                return;
            }
            try {
                root.parse(d);
                root.lastError = "";
            } catch (e) {
                root.lastError = "unreadable";
            }
        });
    }

    // Brightness in percent (the bridge's 1..254 isn't exposed).
    function pctFromBri(b: var): var {
        return typeof b === "number" ? Math.round(b / 254 * 100) : null;
    }

    function briFromPct(pct: int): int {
        return Math.max(1, Math.min(254, Math.round(Math.min(100, pct) / 100 * 254)));
    }

    // Hue / saturation → hex for the swatches. Value forced to 1: a swatch
    // shows the light's hue, not its brightness (a dimmed light would
    // otherwise look grey).
    function hexFromHueSat(hue: var, sat: var): string {
        if (typeof hue !== "number")
            return "";
        const h = hue * 360 / 65535;
        const c = (sat ?? 0) / 254;
        const x = c * (1 - Math.abs((h / 60) % 2 - 1));
        const m = 1 - c;
        const rgb = [[c, x, 0], [x, c, 0], [0, c, x], [0, x, c], [x, 0, c], [c, 0, x]][Math.min(5, Math.floor(h / 60))];
        const hex = v => Math.floor((v + m) * 255).toString(16).padStart(2, "0");
        return `#${hex(rgb[0])}${hex(rgb[1])}${hex(rgb[2])}`;
    }

    // Hex → { hue, sat } in the bridge's scales; the hex's brightness is
    // ignored (the brightness slider sets it; mixing it in would make the
    // light jump on every color change).
    function hueSatFromHex(hex: string): var {
        const h = hex.trim().replace(/^#/, "");
        const r = parseInt(h.slice(0, 2), 16) / 255, g = parseInt(h.slice(2, 4), 16) / 255, b = parseInt(h.slice(4, 6), 16) / 255;
        const max = Math.max(r, g, b), min = Math.min(r, g, b), d = max - min;
        let deg = d === 0 ? 0 : max === r ? 60 * (((g - b) / d) % 6) : max === g ? 60 * ((b - r) / d + 2) : 60 * ((r - g) / d + 4);
        if (deg < 0)
            deg += 360;
        return { hue: Math.floor(deg / 360 * 65535), sat: Math.round((max === 0 ? 0 : d / max) * 254) };
    }

    // Kelvin → mired, within what Hue bulbs take (153-500: ~6500-2000 K).
    function miredFromKelvin(kelvin: int): int {
        return Math.max(153, Math.min(500, Math.floor(1000000 / Math.max(1, kelvin))));
    }

    // The bridge's room class ("Living room", "TV") as the model's
    // identifier ("LivingRoom", "Tv").
    function classId(cls: string): string {
        return cls.split(/[^A-Za-z0-9]+/).filter(w => w).map(w => w[0].toUpperCase() + w.slice(1).toLowerCase()).join("");
    }

    function parse(d: var): void {
        const map = {};
        for (const id in d.lights ?? {}) {
            const l = d.lights[id];
            const s = l.state ?? {};
            map[id] = { id: id, name: l.name, on: !!s.on, reachable: s.reachable !== false, brightness: pctFromBri(s.bri) ?? 0, color: hexFromHueSat(s.hue, s.sat) };
        }
        lights = map;

        const scenes = [];
        const groupsOf = {};
        for (const id in d.scenes ?? {}) {
            const s = d.scenes[id];
            scenes.push({ id: id, name: s.name, group: s.group ?? "" });
            groupsOf[id] = s.group || "0";
        }
        sceneGroups = groupsOf;

        const out = [];
        for (const id in d.groups ?? {}) {
            const g = d.groups[id];
            const ids = g.lights ?? [];
            if (!g.class || ids.length === 0)
                continue;
            // No group brightness on the bridge: the average of its lights
            // that are on (lights off would drag it towards zero).
            const lit = ids.map(i => map[i]).filter(l => l && l.on);
            const bris = lit.map(l => l.brightness);
            out.push({
                id: id,
                name: g.name,
                cls: classId(g.class),
                on: !!g.state?.any_on,
                brightness: bris.length ? Math.floor(bris.reduce((a, b) => a + b, 0) / bris.length) : 0,
                color: lit.find(l => l.color)?.color ?? "",
                scenes: scenes.filter(s => s.group === id).map(s => ({ id: s.id, name: s.name })).sort((a, b) => a.name.localeCompare(b.name)),
                lights: ids
            });
        }
        rooms = out.sort((a, b) => a.name.localeCompare(b.name));
        loaded = true;
    }

    // ── Actions ─────────────────────────────────────────────────────────

    // One request per action (no queue); a read 400 ms after.
    function run(req: var): void {
        if (!available)
            return;
        request("PUT", `${base}/${req.path}`, req.body, null, 5000);
        readBack.restart();
    }

    function groupAction(id: string, body: var): var {
        return { path: `groups/${id}/action`, body: body };
    }

    function lightState(id: string, body: var): var {
        return { path: `lights/${id}/state`, body: body };
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
        run(groupAction(id, { on: !r.on }));
    }

    function setRoomBrightness(id: string, pct: int): void {
        patchRoom(id, { on: true, brightness: pct });
        forgetScene(id);
        throttle.send(groupAction(id, { on: true, bri: briFromPct(pct) }));
    }

    function setRoomColor(id: string, hex: string): void {
        patchRoom(id, { on: true, color: hex });
        forgetScene(id);
        throttle.send(groupAction(id, Object.assign({ on: true }, hueSatFromHex(hex))));
    }

    function setRoomWhite(id: string, kelvin: int): void {
        patchRoom(id, { on: true, color: kelvinColor(kelvin) });
        forgetScene(id);
        throttle.send(groupAction(id, { on: true, ct: miredFromKelvin(kelvin) }));
    }

    function allOff(): void {
        for (const r of rooms)
            if (r.on) {
                patchRoom(r.id, { on: false });
                run(groupAction(r.id, { on: false }));
            }
    }

    function toggleLight(id: string): void {
        const l = lights[id];
        if (!l || !l.reachable)
            return;
        patchLight(id, { on: !l.on });
        run(lightState(id, { on: !l.on }));
    }

    function setLightBrightness(id: string, pct: int): void {
        patchLight(id, { on: true, brightness: pct });
        throttle.send(lightState(id, { on: true, bri: briFromPct(pct) }));
    }

    function setLightColor(id: string, hex: string): void {
        patchLight(id, { on: true, color: hex });
        throttle.send(lightState(id, Object.assign({ on: true }, hueSatFromHex(hex))));
    }

    function setLightWhite(id: string, kelvin: int): void {
        patchLight(id, { on: true, color: kelvinColor(kelvin) });
        throttle.send(lightState(id, { on: true, ct: miredFromKelvin(kelvin) }));
    }

    // A scene starts by being pushed on its group (group 0, all the
    // lights, for a scene without one).
    function startScene(roomId: string, sceneId: string): void {
        const next = Object.assign({}, activeScene);
        next[roomId] = sceneId;
        activeScene = next;
        patchRoom(roomId, { on: true });
        run(groupAction(sceneGroups[sceneId] ?? "0", { scene: sceneId }));
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

    // Sliders and color drags: at most one request every 150 ms per light
    // or group, the last one always sent.
    QtObject {
        id: throttle

        // path → the latest request not sent yet.
        property var pending: ({})

        function send(req: var): void {
            if (!timer.running) {
                root.run(req);
                timer.start();
            } else {
                pending[req.path] = req;
            }
        }

        readonly property Timer timer: Timer {
            interval: 150
            onTriggered: {
                const reqs = Object.values(throttle.pending);
                throttle.pending = {};
                for (const req of reqs)
                    root.run(req);
                if (reqs.length > 0)
                    start();
            }
        }
    }

    // The bridge takes a moment to reflect a change.
    Timer {
        id: readBack
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        running: root.refCount > 0 && root.available
        interval: 10000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ── Discovery and pairing ───────────────────────────────────────────

    // Bridges found on the network: [ip].
    property var discovered: []
    property bool discovering: false
    // "" | "none" (nothing found) | "failed" (no answer from the service)
    property string discoverError: ""

    // Two sources at once: mDNS on the local network (avahi-browse, when
    // installed: works offline) and Philips' discovery service (lists the
    // bridges seen behind the same public address; often empty).
    property int discoverPending: 0
    property bool discoverAnswered: false

    function addDiscovered(ips: var): void {
        const next = discovered.slice();
        for (const ip of ips)
            if (ip && !next.includes(ip))
                next.push(ip);
        discovered = next;
    }

    function discoverDone(answered: bool): void {
        if (answered)
            discoverAnswered = true;
        if (--discoverPending > 0)
            return;
        discovering = false;
        if (discovered.length === 0)
            discoverError = discoverAnswered ? "none" : "failed";
    }

    function discover(): void {
        if (discovering)
            return;
        discovering = true;
        discoverError = "";
        discoverAnswered = false;
        discovered = [];
        discoverPending = 2;
        mdns.running = true;
        request("GET", "https://discovery.meethue.com/", null, (status, d) => {
            const ok = status === 200 && Array.isArray(d);
            if (ok)
                root.addDiscovered(d.map(b => b.internalipaddress));
            root.discoverDone(ok);
        }, 10000);
    }

    // `avahi-browse -rpt`: resolved services as "=;iface;proto;name;type;
    // domain;host;address;port;txt" lines; IPv4 addresses kept.
    Process {
        id: mdns
        command: ["timeout", "6", "avahi-browse", "-rpt", "_hue._tcp"]
        // Ends with the process (also when avahi isn't installed: empty).
        stdout: StdioCollector {
            onStreamFinished: {
                root.addDiscovered(text.split("\n").map(l => l.split(";")).filter(f => f[0] === "=" && /^\d+\.\d+\.\d+\.\d+$/.test(f[7] ?? "")).map(f => f[7]));
                root.discoverDone(text.length > 0);
            }
        }
    }

    // Pairing: the user is registered once the bridge's link button has
    // been pressed; asked every 2 s for 30 s (error 101 = not pressed yet).
    property bool pairing: false
    property string pairingIp: ""
    property int pairRemaining: 0
    // "" | "timeout" | "unreachable" | "failed"
    property string pairError: ""

    // The devicetype names this computer in the bridge's app list.
    FileView {
        id: hostnameFile
        path: "/etc/hostname"
        printErrors: false
    }
    readonly property string deviceType: `lc-shell#${(hostnameFile.text() || "linux").trim().replace(/[^A-Za-z0-9._-]/g, "").slice(0, 19) || "linux"}`

    function pair(ip: string): void {
        const address = ip.trim();
        if (!address || pairing)
            return;
        pairingIp = address;
        pairError = "";
        pairRemaining = 30;
        pairing = true;
        pairTick.start();
        tryPair();
    }

    function cancelPairing(): void {
        pairing = false;
        pairTick.stop();
    }

    function tryPair(): void {
        request("POST", `http://${pairingIp}/api`, { devicetype: deviceType }, (status, d) => {
            if (!root.pairing)
                return;
            const r = Array.isArray(d) ? d[0] : null;
            if (r?.success?.username) {
                root.cancelPairing();
                root.saveCredentials(root.pairingIp, r.success.username);
            } else if (status === 0) {
                root.cancelPairing();
                root.pairError = "unreachable";
            } else if (r?.error?.type !== 101) {
                root.cancelPairing();
                root.pairError = "failed";
            }
        }, 4000);
    }

    Timer {
        id: pairTick
        interval: 1000
        repeat: true
        onTriggered: {
            root.pairRemaining--;
            if (root.pairRemaining <= 0) {
                root.cancelPairing();
                root.pairError = "timeout";
            } else if (root.pairRemaining % 2 === 0) {
                root.tryPair();
            }
        }
    }
}
