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
    }

    IpcHandler {
        target: "shell"

        // Full reload; also picks up .js changes, which hot reload ignores.
        function reload(): void {
            Quickshell.reload(true);
        }
    }
}
