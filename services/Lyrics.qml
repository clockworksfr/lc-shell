pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Synced lyrics of the active player's track, from lrclib.net (only the
// track's artist, title and duration are sent). Results, including
// "not found", are cached in the cache dir.
//
// `lines`: [{ time (s), text }], `index`: current line (-1 before the first).
// Position is polled only while something displays lyrics (`refCount`).
Singleton {
    id: root

    property int refCount: 0

    readonly property var player: Players.active
    readonly property string artist: player?.trackArtist ?? ""
    readonly property string title: player?.trackTitle ?? ""
    // Streams report no (or an absurd) length: treat as unknown.
    readonly property real length: player?.lengthSupported && player.length > 0 && player.length < 86400 ? player.length : 0
    readonly property string key: artist && title ? `${artist}\u001f${title}` : ""

    // "idle" | "loading" | "found" | "plain" | "missing" | "error"
    property string status: "idle"
    property var lines: []
    property string plainText
    property real position: 0
    // Sample lines (reviews, screenshots): the player no longer moves them.
    property bool demo: false

    // Sample synced lyrics, current line `line` (< 0: back to the track's).
    function setDemo(line: int): void {
        if (line < 0) {
            demo = false;
            fetch();
            return;
        }
        demo = true;
        const sample = ["Under the neon of a sleepless town", "we keep on walking", "where the night goes on and on without a single word to say", "♪", "Short line", "and a very long line that never seems to end, wrapping over and over across the cell", "till the morning comes", "the last line"];
        lines = sample.map((text, i) => ({ time: i * 4, text: text === "♪" ? "" : text }));
        status = "found";
        position = Math.min(line, sample.length - 1) * 4 + 1;
    }
    readonly property int index: {
        let current = -1;
        for (let i = 0; i < lines.length && lines[i].time <= position + 0.2; i++)
            current = i;
        return current;
    }

    // key -> { synced, plain } ; synced/plain null when missing.
    property var cache: ({})

    // Track metadata changes field by field: wait for it to settle.
    onKeyChanged: settle.restart()

    Timer {
        id: settle
        interval: 300
        onTriggered: root.fetch()
    }

    function parse(lrc: string): var {
        const out = [];
        for (const raw of (lrc ?? "").split("\n")) {
            // No String.matchAll in QML's engine: exec loop.
            const stamp = /\[(\d+):(\d+(?:\.\d+)?)\]/g;
            const times = [];
            let m;
            while ((m = stamp.exec(raw)) !== null)
                times.push(Number(m[1]) * 60 + Number(m[2]));
            if (times.length === 0)
                continue;
            const text = raw.replace(/\[[^\]]*\]/g, "").trim();
            for (const time of times)
                out.push({ time: time, text: text });
        }
        return out.sort((a, b) => a.time - b.time);
    }

    function apply(entry: var): void {
        lines = entry?.synced ? parse(entry.synced) : [];
        plainText = entry?.plain ?? "";
        status = lines.length > 0 ? "found" : plainText ? "plain" : "missing";
    }

    function fetch(): void {
        if (demo)
            return;
        lines = [];
        plainText = "";
        if (!key) {
            status = "idle";
            return;
        }
        if (key in cache) {
            apply(cache[key]);
            return;
        }
        status = "loading";
        const requested = key;
        // 1. exact match without album (album names differ between sources),
        // 2. search, keeping the synced result closest in duration.
        const base = `artist_name=${encodeURIComponent(artist)}&track_name=${encodeURIComponent(title)}`;
        const duration = length > 0 ? `&duration=${Math.round(length)}` : "";
        get(`https://lrclib.net/api/get?${base}${duration}`, (code, data) => {
            if (requested !== root.key)
                return;
            if (code === 200 && (data.syncedLyrics || data.plainLyrics)) {
                remember(requested, { synced: data.syncedLyrics ?? null, plain: data.plainLyrics ?? null });
                return;
            }
            if (code !== 200 && code !== 404) {
                root.status = "error";
                return;
            }
            get(`https://lrclib.net/api/search?${base}`, (code, results) => {
                if (requested !== root.key)
                    return;
                if (code !== 200 || !Array.isArray(results)) {
                    root.status = code === 404 ? "missing" : "error";
                    if (code === 404)
                        remember(requested, { synced: null, plain: null });
                    return;
                }
                const scored = results.filter(r => r.syncedLyrics || r.plainLyrics).sort((a, b) => (!!b.syncedLyrics - !!a.syncedLyrics) || Math.abs((a.duration ?? 0) - root.length) - Math.abs((b.duration ?? 0) - root.length));
                const best = scored[0];
                remember(requested, best ? { synced: best.syncedLyrics ?? null, plain: best.plainLyrics ?? null } : { synced: null, plain: null });
            });
        });
    }

    function get(url: string, done: var): void {
        const request = new XMLHttpRequest();
        request.open("GET", url);
        request.setRequestHeader("Lrclib-Client", "lc-shell");
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            let data = null;
            try {
                data = JSON.parse(request.responseText);
            } catch (e) {}
            if (request.status !== 200 && request.status !== 404)
                console.warn(`lyrics: HTTP ${request.status} for ${url}`);
            done(request.status, data);
        };
        request.send();
    }

    function remember(key: string, entry: var): void {
        const next = Object.assign({}, cache);
        next[key] = entry;
        // Keep the cache small: the 300 most recent tracks.
        const keys = Object.keys(next);
        for (const old of keys.slice(0, Math.max(0, keys.length - 300)))
            delete next[old];
        cache = next;
        cacheFile.setText(JSON.stringify(next));
        if (key === root.key)
            apply(entry);
    }

    Timer {
        interval: 250
        repeat: true
        running: root.refCount > 0 && !root.demo && (root.player?.isPlaying ?? false) && root.lines.length > 0
        onTriggered: {
            root.player.positionChanged();
            root.position = root.player.position;
        }
    }

    // Seeks while paused still move the highlighted line.
    Connections {
        target: root.player
        function onPositionChanged(): void {
            if (!root.demo)
                root.position = root.player.position;
        }
    }

    FileView {
        id: cacheFile
        path: Quickshell.cachePath("lyrics.json")
        printErrors: false
        onLoaded: {
            try {
                root.cache = JSON.parse(text());
            } catch (e) {
                root.cache = {};
            }
            root.fetch();
        }
    }
}
