pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.services

// Clipboard manager: history captured by `wl-paste --watch` (capture.py),
// pins, tags, retention, copy back and direct paste into the window that
// had the focus. The manager window is windows/clipboard.
//
// Store ($XDG_DATA_HOME/lc/clipboard, LC_CLIPBOARD_DIR for tests):
//   index.json   { version, tags: [{ id, name, color }], items: [...] }
//   blobs/       one payload per item, named by its SHA-1 (dedupe)
//
// An item:
//   id (SHA-1 of the payload), kind (text, code, link, color, char, image,
//   file), mime, file (blob name), size (bytes), text (first 16 KiB, not
//   for images), truncated, w, h (images), app (focused app at capture),
//   time (first copy, ms), last (last copy or use, ms), count, pinned,
//   tags ([tag id])
//
// Settings (`clipboard.*`): enabled, position, maxItems, maxDays,
// keepTagged, images, maxImageMB, ignoreSensitive, ignoreApps,
// pasteOnEnter, terminals.
Singleton {
    id: root

    // --- Settings ---

    readonly property var config: Config.get("clipboard") ?? {}
    readonly property bool enabled: config.enabled ?? true
    readonly property string position: config.position ?? "bottom"
    readonly property int maxItems: config.maxItems ?? 500
    readonly property int maxDays: config.maxDays ?? 0
    readonly property bool keepTagged: config.keepTagged ?? true
    readonly property bool images: config.images ?? true
    readonly property real maxImageMB: config.maxImageMB ?? 20
    readonly property bool ignoreSensitive: config.ignoreSensitive ?? true
    readonly property var ignoreApps: (config.ignoreApps ?? []).map(a => String(a).toLowerCase())
    readonly property bool pasteOnEnter: config.pasteOnEnter ?? true
    readonly property var terminals: (config.terminals ?? []).map(a => String(a).toLowerCase())

    // Fixed palette of tag colors (picked by name, drawn from the theme-free
    // swatches below so tags look the same on every theme).
    readonly property var tagColors: ({
            red: "#E5534B",
            orange: "#E8833A",
            yellow: "#E3B341",
            green: "#57AB5A",
            teal: "#39C5BB",
            blue: "#4A8FE7",
            purple: "#9A6DD7",
            pink: "#E06FA8",
            grey: "#8B949E"
        })
    readonly property var tagColorNames: Object.keys(tagColors)

    readonly property string dataHome: Quickshell.env("XDG_DATA_HOME") || `${Quickshell.env("HOME")}/.local/share`
    readonly property string dir: Quickshell.env("LC_CLIPBOARD_DIR") || `${dataHome}/lc/clipboard`
    readonly property string blobDir: `${dir}/blobs`
    // LC_CLIPBOARD_CAPTURE=0: no capture (tests on a sample store).
    readonly property bool captureAllowed: Quickshell.env("LC_CLIPBOARD_CAPTURE") !== "0"

    // --- State ---

    // Newest (last use) first.
    property var items: []
    property var tags: []
    property bool loaded: false
    // Incognito: nothing is recorded until resumed (not persisted).
    property bool paused: false

    readonly property int count: items.length
    readonly property int pinnedCount: items.filter(i => i.pinned).length

    // Manager window.
    property bool opened: false
    property string screenName
    // Window focused when the manager opened: where paste goes.
    property string targetAddress
    property string targetClass

    // --- Window ---

    function open(): void {
        const active = Hyprland.activeToplevel;
        targetAddress = active?.address ?? "";
        targetClass = active?.lastIpcObject?.class ?? active?.wayland?.appId ?? "";
        screenName = Hyprland.focusedMonitor?.name ?? "";
        opened = true;
    }

    function close(): void {
        opened = false;
    }

    function toggle(): void {
        if (opened)
            close();
        else
            open();
    }

    // --- Lookups ---

    function item(id: string): var {
        return items.find(i => i.id === id) ?? null;
    }

    function tag(id: string): var {
        return tags.find(t => t.id === id) ?? null;
    }

    function blobPath(entry: var): string {
        return entry?.file ? `${blobDir}/${entry.file}` : "";
    }

    // Paths of a file item (text/uri-list), decoded.
    function filePaths(entry: var): var {
        return (entry?.text ?? "").split(/\r?\n/).map(l => l.trim()).filter(l => l && !l.startsWith("#")).map(l => {
            if (!l.startsWith("file://"))
                return l;
            try {
                return decodeURIComponent(l.slice(7).replace(/^[^/]*/, ""));
            } catch (e) {
                return l.slice(7);
            }
        });
    }

    // Normalized color of a color item, for a swatch.
    function colorValue(entry: var): string {
        const t = (entry?.text ?? "").trim();
        return /^[0-9a-f]{6}$/i.test(t) ? `#${t}` : t;
    }

    // --- Classification ---

    readonly property var imageExtensions: ["png", "jpg", "jpeg", "webp", "gif", "bmp", "svg", "avif"]

    function classify(record: var): string {
        if (record.mime === "text/uri-list")
            return "file";
        if ((record.mime ?? "").startsWith("image/"))
            return "image";
        const t = (record.text ?? "").trim();
        if (/^#(?:[0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(t) || /^(?:rgba?|hsla?|oklch|oklab)\([\d\s.,%/+-]+\)$/i.test(t))
            return "color";
        if (/^(?:https?:\/\/|ftp:\/\/|mailto:|www\.)\S+$/i.test(t))
            return "link";
        // A character or an emoji (a few code units, no letters or digits).
        if (t.length > 0 && t.length <= 8 && !/[\sA-Za-z0-9]/.test(t))
            return "char";
        if (looksLikeCode(t))
            return "code";
        return "text";
    }

    function looksLikeCode(t: string): bool {
        if (t.length < 6)
            return false;
        const lines = t.split("\n");
        const keywords = (t.match(/\b(?:function|const|let|var|def|class|import|export|return|fn|pub|struct|impl|package|namespace|SELECT|FROM|WHERE|INSERT|UPDATE|elif|lambda|async|await|println|printf|console|property|readonly)\b/g) ?? []).length;
        const symbols = (t.match(/[{}();=<>[\]$|&\\]/g) ?? []).length;
        const indented = lines.filter(l => /^(?:\t| {2,})\S/.test(l)).length;
        const endings = lines.filter(l => /[;{}:]\s*$/.test(l)).length;
        const score = symbols / t.length * 10 + Math.min(keywords, 4) * 0.4 + (lines.length > 1 ? (indented + endings) / lines.length : 0);
        return score >= 1.2;
    }

    // --- Capture ---

    function onCaptured(line: string): void {
        let record;
        try {
            record = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (record.state === "error")
            console.warn(`clipboard capture: ${record.error}`);
        // Sensitive copies (password managers) never reach here when
        // ignoreSensitive is set: capture.py drops them.
        if (record.state !== "data" || paused || !enabled)
            return;
        const app = ToplevelManager.activeToplevel?.appId ?? Hyprland.activeToplevel?.lastIpcObject?.class ?? "";
        if (app && ignoreApps.includes(app.toLowerCase()))
            return;
        if (!images && record.mime.startsWith("image/"))
            return;
        add(record, app);
    }

    function add(record: var, app: string): void {
        const now = Date.now();
        const existing = item(record.hash);
        let entry;
        if (existing) {
            entry = Object.assign({}, existing, { last: now, count: (existing.count ?? 1) + 1 });
            if (!entry.app && app)
                entry.app = app;
        } else {
            entry = {
                id: record.hash,
                mime: record.mime,
                file: record.file,
                size: record.size,
                time: now,
                last: now,
                count: 1,
                app: app,
                pinned: false,
                tags: []
            };
            if (record.text !== undefined) {
                entry.text = record.text;
                entry.truncated = !!record.truncated;
            }
            if (record.w) {
                entry.w = record.w;
                entry.h = record.h;
            }
            entry.kind = classify(entry);
        }
        setItems([entry, ...items.filter(i => i.id !== entry.id)]);
    }

    // Applies the retention rules, deletes the blobs of dropped items,
    // writes the index.
    function setItems(next: var): void {
        const now = Date.now();
        const maxAge = maxDays > 0 ? maxDays * 86400000 : Infinity;
        const kept = [];
        const dropped = [];
        let loose = 0;
        for (const entry of next) {
            const keep = entry.pinned || (keepTagged && (entry.tags ?? []).length > 0);
            if (keep) {
                kept.push(entry);
            } else if (loose < maxItems && now - entry.last <= maxAge) {
                kept.push(entry);
                loose++;
            } else {
                dropped.push(entry);
            }
        }
        items = kept;
        deleteBlobs(dropped);
        save();
    }

    function deleteBlobs(entries: var): void {
        const files = entries.filter(e => e.file).map(e => blobPath(e));
        if (files.length)
            Quickshell.execDetached(["rm", "-f", "--", ...files]);
    }

    // --- Actions ---

    function update(id: string, changes: var): void {
        setItems(items.map(i => i.id === id ? Object.assign({}, i, changes) : i));
    }

    function togglePin(id: string): void {
        const entry = item(id);
        if (entry)
            update(id, { pinned: !entry.pinned });
    }

    function remove(id: string): void {
        const entry = item(id);
        if (!entry)
            return;
        items = items.filter(i => i.id !== id);
        deleteBlobs([entry]);
        save();
    }

    // Clears the history; `all` also clears pinned and tagged items.
    function clear(all: bool): void {
        const kept = all ? [] : items.filter(i => i.pinned || (i.tags ?? []).length > 0);
        deleteBlobs(items.filter(i => !kept.includes(i)));
        items = kept;
        save();
    }

    function setPaused(value: bool): void {
        paused = value;
    }

    // Copies an item back; `asText`: paths of a file item as plain text.
    // `paste`: then sends the paste shortcut to the window focused before
    // the manager opened.
    function copy(id: string, asText: bool, paste: bool): void {
        const entry = item(id);
        if (!entry)
            return;
        // Used: back to the top (the capture of our own copy counts it).
        setItems([Object.assign({}, entry, { last: Date.now() }), ...items.filter(i => i.id !== id)]);
        if (asText && entry.kind === "file")
            copier.command = ["sh", "-c", "printf '%s' \"$1\" | wl-copy --type 'text/plain;charset=utf-8'", "sh", filePaths(entry).join("\n")];
        else
            copier.command = ["sh", "-c", "wl-copy --type \"$1\" < \"$2\"", "sh", entry.mime, blobPath(entry)];
        copier.paste = paste && !!targetAddress;
        copier.address = targetAddress;
        copier.terminal = terminals.includes(targetClass.toLowerCase());
        copier.running = true;
    }

    // --- Tags ---

    function createTag(name: string, color: string): string {
        const clean = name.trim();
        if (!clean)
            return "";
        const found = tags.find(t => t.name.toLowerCase() === clean.toLowerCase());
        if (found)
            return found.id;
        const id = `t${Date.now().toString(36)}`;
        const used = tags.map(t => t.color);
        const free = tagColorNames.find(c => !used.includes(c)) ?? tagColorNames[tags.length % tagColorNames.length];
        tags = [...tags, { id: id, name: clean, color: tagColors[color] ? color : free }];
        save();
        return id;
    }

    function updateTag(id: string, changes: var): void {
        tags = tags.map(t => t.id === id ? Object.assign({}, t, changes) : t);
        save();
    }

    // Removes the tag from its items too (they may become prunable).
    function deleteTag(id: string): void {
        tags = tags.filter(t => t.id !== id);
        setItems(items.map(i => (i.tags ?? []).includes(id) ? Object.assign({}, i, { tags: i.tags.filter(t => t !== id) }) : i));
    }

    function moveTag(id: string, delta: int): void {
        const index = tags.findIndex(t => t.id === id);
        const to = index + delta;
        if (index < 0 || to < 0 || to >= tags.length)
            return;
        const next = tags.slice();
        next.splice(to, 0, next.splice(index, 1)[0]);
        tags = next;
        save();
    }

    function toggleTag(id: string, tagId: string): void {
        const entry = item(id);
        if (!entry)
            return;
        const current = entry.tags ?? [];
        update(id, { tags: current.includes(tagId) ? current.filter(t => t !== tagId) : [...current, tagId] });
    }

    // --- Persistence ---

    function save(): void {
        if (loaded)
            saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: index.setText(JSON.stringify({ version: 1, tags: root.tags, items: root.items }))
    }

    // The store may not exist yet; private (copies can hold secrets).
    Process {
        running: true
        command: ["sh", "-c", "mkdir -p \"$1\" && chmod 700 \"$2\"", "sh", root.blobDir, root.dir]
    }

    // Blobs no item refers to (crash between capture and index write,
    // interrupted capture): removed a while after loading. Only files older
    // than a minute: a capture in flight has its blob before its item.
    Timer {
        running: root.loaded
        interval: 30000
        onTriggered: sweep.running = true
    }

    Process {
        id: sweep
        command: ["find", root.blobDir, "-type", "f", "-mmin", "+1", "-printf", "%f\\n"]
        stdout: StdioCollector {
            onStreamFinished: {
                const known = new Set(root.items.map(i => i.file));
                const stray = text.split("\n").filter(f => f && !known.has(f));
                if (stray.length)
                    Quickshell.execDetached(["rm", "-f", "--", ...stray.map(f => `${root.blobDir}/${f}`)]);
            }
        }
    }

    FileView {
        id: index
        path: `${root.dir}/index.json`
        atomicWrites: true
        printErrors: false
        blockLoading: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.tags = data.tags ?? [];
                root.items = (data.items ?? []).map(i => Object.assign({ tags: [], count: 1 }, i, { kind: i.kind ?? root.classify(i) }));
            } catch (e) {
                console.warn(`clipboard: ${path}: invalid index, starting empty (${e})`);
            }
            root.loaded = true;
            // Age limit and size limit changed while away.
            root.setItems(root.items);
        }
        onLoadFailed: error => {
            // No index yet (first run).
            root.loaded = true;
        }
    }

    // Retention by age also applies while the shell runs for days.
    Timer {
        interval: 3600 * 1000
        running: root.loaded && root.maxDays > 0
        repeat: true
        onTriggered: root.setItems(root.items)
    }

    // Settings changed: limits apply at once.
    onMaxItemsChanged: if (loaded) setItems(items)
    onMaxDaysChanged: if (loaded) setItems(items)
    onKeepTaggedChanged: if (loaded) setItems(items)

    // One capture per selection change. Runs while paused too (events are
    // dropped): resuming doesn't record what was copied meanwhile.
    readonly property bool watching: loaded && swept && enabled && captureAllowed
    readonly property string capturePath: `${Quickshell.shellDir}/clipboard/capture.py`
    // setpriv: the watcher dies with the shell (a killed shell, e.g. by its
    // restart loop, would otherwise leave it running, orphaned).
    readonly property var watchCommand: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--watch", "python3", "-I", capturePath, dir, String(images ? Math.round(maxImageMB * 1000 * 1000) : 0), ignoreSensitive ? "1" : "0"]

    // Watchers of this store left by an earlier shell: stopped before ours
    // starts.
    property bool swept: false

    Process {
        running: true
        command: ["pkill", "-f", `^wl-paste --watch python3 -I ${root.capturePath} ${root.dir} `]
        onExited: root.swept = true
    }

    onWatchingChanged: watcher.running = watching
    // New options: restart with them (onExited starts it again).
    onWatchCommandChanged: if (watcher.running) watcher.running = false

    Process {
        id: watcher
        command: root.watchCommand
        stdout: SplitParser {
            onRead: line => root.onCaptured(line)
        }
        // Stopped for new options, or wl-paste gone (compositor restart,
        // protocol missing): start again a bit later.
        onExited: code => restart.start()
    }

    Timer {
        id: restart
        interval: 1500
        onTriggered: watcher.running = root.watching
    }

    // wl-copy, then the paste shortcut once the selection is set.
    Process {
        id: copier

        property bool paste
        property string address
        property bool terminal

        onExited: code => {
            if (code === 0 && paste)
                pasteTimer.start();
        }
    }

    // Focus is back on the target window once the manager is gone.
    Timer {
        id: pasteTimer
        interval: 120
        onTriggered: {
            const address = copier.address.startsWith("0x") ? copier.address : `0x${copier.address}`;
            Hyprland.dispatch(`hl.dsp.send_shortcut({ mods = "${copier.terminal ? "CTRL SHIFT" : "CTRL"}", key = "V", window = "address:${address}" })`);
        }
    }
}
