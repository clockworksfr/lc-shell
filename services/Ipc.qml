import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Entry points for Hyprland binds: qs -c lc ipc call <target> <function>
// List them with: qs -c lc ipc show
// Avoid function names that clash with qs ipc subcommands (show, call...).
Scope {
    IpcHandler {
        target: "bar"

        function toggle(): void {
            ShellState.barVisible = !ShellState.barVisible;
        }
        function open(): void {
            ShellState.barVisible = true;
        }
        function close(): void {
            ShellState.barVisible = false;
        }
        // Toggle a block's panel: volume, network, bluetooth, battery,
        // notifications. On the focused screen, or the named one.
        function panel(type: string): void {
            ShellState.panelRequested(type, "");
        }
        function panelOn(type: string, screen: string): void {
            ShellState.panelRequested(type, screen);
        }
        // One line per shown widget: "screen type x y width height", in
        // global coordinates (center = where to hover).
        function widgets(): string {
            return ShellState.slots.filter(s => s.visible && s.host).map(s => {
                const bar = s.host;
                const p = s.mapToItem(bar.contentItem, 0, 0);
                const scr = bar.screen;
                const o = bar.origin();
                const ox = o.x;
                const oy = o.y;
                return `${scr.name} ${s.type} ${Math.round(scr.x + ox + p.x)} ${Math.round(scr.y + oy + p.y)} ${Math.round(s.width)} ${Math.round(s.height)}`;
            }).join("\n");
        }
        // Show a block's hover card without hovering (screenshots, reviews);
        // "" hides it. On every screen with a bar (or `showCardOn`).
        function showCard(type: string): void {
            ShellState.cardRequested(type, "");
        }
        function showCardOn(type: string, screen: string): void {
            ShellState.cardRequested(type, screen);
        }
        // Reviews: <path>-bar.png and, a card being open, <path>-card.png.
        function snapshot(screen: string, path: string): void {
            ShellState.barSnapshotRequested(screen, path);
        }
        function hideCard(): void {
            ShellState.cardRequested("", "");
        }
        // The bar's right-click menu ("bar") or a tray item's menu
        // ("tray:0", "tray:1"…), on the focused screen.
        function menu(name: string): void {
            ShellState.menuRequested(name || "bar", "");
        }
        // Edit mode: enter, leave keeping changes, leave restoring them.
        function edit(): void {
            ShellState.editing = true;
        }
        function done(): void {
            BarEditor.done();
        }
        // Edit mode: select a widget of the focused screen's bar by type,
        // resize the selection (compact | normal | extended).
        function select(type: string): void {
            const name = Hyprland.focusedMonitor?.name ?? "";
            const slot = ShellState.slots.find(s => s.type === type && s.screen?.name === name && !!s.host);
            BarEditor.selected = slot ? slot.at : null;
        }
        function resize(size: string): void {
            if (BarEditor.selected && BarEditor.sizes.includes(size))
                BarEditor.setSize(BarEditor.selected, size);
        }
        // Puts the bars back as before the last "done" (the toast's Undo).
        function undoSave(): void {
            BarEditor.revertSave();
        }
        function discard(): void {
            BarEditor.discard();
        }
        // Hover card: "visible type screen" or "hidden".
        function card(): string {
            const c = ShellState.card;
            return c.visible ? `visible ${c.type} ${c.screen}` : "hidden";
        }
    }

    IpcHandler {
        target: "audio"

        function increment(): void {
            Audio.increment();
        }
        function decrement(): void {
            Audio.decrement();
        }
        function toggleMute(): void {
            Audio.toggleMute();
        }
        function toggleMicMute(): void {
            Audio.toggleSourceMute();
        }
    }

    IpcHandler {
        target: "media"

        function togglePlaying(): void {
            Players.togglePlaying();
        }
        function next(): void {
            Players.next();
        }
        function previous(): void {
            Players.previous();
        }
        // Switch the controlled player when several are open.
        function cycle(): void {
            Players.cycle();
        }
        // Controlled player and track, then the other players.
        function info(): string {
            const describe = p => `${p.identity}: ${[p.trackArtist, p.trackTitle].filter(s => !!s).join(" - ")} (${p.isPlaying ? "playing" : "paused"})`;
            const active = Players.active;
            return [active ? `* ${describe(active)}` : "* none", ...Players.list.filter(p => p !== active).map(p => `  ${describe(p)}`)].join("\n");
        }
    }

    // Acts on the focused screen (backlight or DDC/CI).
    IpcHandler {
        target: "brightness"

        function increment(): void {
            Brightness.increment();
        }
        function decrement(): void {
            Brightness.decrement();
        }
    }

    IpcHandler {
        target: "notifs"

        function toggleDnd(): void {
            NotificationCenter.setDnd(!NotificationCenter.dnd);
        }
        function clear(): void {
            NotificationCenter.clearAll();
        }
        function markRead(): void {
            NotificationCenter.markRead();
        }
    }

    IpcHandler {
        target: "wallpaper"

        // Every screen; `~` is expanded.
        function set(path: string): void {
            Wallpaper.set(path, null);
        }
        // Only the focused screen.
        function setHere(path: string): void {
            Wallpaper.set(path, Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null);
        }
        function random(): void {
            Wallpaper.random(null);
        }
        function get(): string {
            return Quickshell.screens.map(s => `${s.name}: ${Wallpaper.pathFor(s) || "-"}`).join("\n");
        }
    }

    IpcHandler {
        target: "lyrics"

        // "idle" | "loading" | "found" | "plain" | "missing" | "error"
        function status(): string {
            return Lyrics.status;
        }
        // Current synced line (empty if none).
        function current(): string {
            return Lyrics.lines[Lyrics.index]?.text ?? "";
        }
        // Sample synced lyrics on line n (reviews, screenshots); -1: off.
        function demo(line: int): void {
            Lyrics.setDemo(line);
        }
    }

    IpcHandler {
        target: "shell"

        // Screenshots: a zone or a window (screens frozen, then the
        // editor), the focused screen, the active window; annotate a file.
        function screenshot(): void {
            Screenshot.region();
        }
        function screenshotScreen(): void {
            Screenshot.screen();
        }
        function screenshotWindow(): void {
            Screenshot.window();
        }
        function screenshotEdit(path: string): void {
            Screenshot.edit(path);
        }

        // Full reload; also picks up .js changes, which hot reload ignores.
        function reload(): void {
            Quickshell.reload(true);
        }
    }
}
