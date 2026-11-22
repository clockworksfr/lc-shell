pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.i18n

// Screenshots, with an editor in the shell (grim, wl-copy):
// - region(): every screen freezes (grim stills, a ShotWindow on each);
//   pick a zone (drag) or a window (click), annotate it in place, then
//   copy (Enter) or save (Ctrl+S);
// - screen(): the focused screen, at once;
// - window(): the active window, at once;
// - edit(file): annotate an image file (the notification's "Annotate").
// Every shot is copied to the clipboard and/or saved (`screenshot.*`),
// then a notification offers Annotate / Save / Open.
Singleton {
    id: root

    readonly property var config: Config.get("screenshot") ?? ({})
    // "" = <Pictures>/Screenshots
    readonly property string dir: config.dir ?? ""
    // Enter: "copy" | "save" | "both"; Ctrl+S always saves (and copies
    // when `copyOnSave`).
    readonly property string enterAction: ["copy", "save", "both"].includes(config.enterAction) ? config.enterAction : "copy"
    readonly property bool copyOnSave: config.copyOnSave ?? true
    readonly property bool notify: config.notify ?? true
    readonly property bool pickWindows: config.pickWindows ?? true
    readonly property bool magnifier: config.magnifier ?? true
    readonly property string fileName: config.fileName || "screenshot_{date}_{time}"

    readonly property string cacheDir: Quickshell.cachePath("screenshots")

    // --- Editor session ---
    // "" (closed) | "freeze" (every screen, pick then annotate) | "file"
    // (one screen, an image file to annotate)
    property string mode: ""
    readonly property bool active: mode !== ""
    // screen name -> still image path (freeze)
    property var stills: ({})
    // screen name -> [{ x, y, w, h, title, cls }] in the screen's
    // coordinates, topmost first (freeze)
    property var windows: ({})
    // The image being edited (file mode).
    property string file
    // Screen holding the selection (keyboard goes there).
    property string screenName
    property bool busy: false

    // Tool state, kept between shots.
    property string tool: "arrow"
    property string color: "red"
    // 0 small, 1 medium, 2 large
    property int stroke: 1
    property bool fill: false

    readonly property var palette: ({
            red: "#E5484D",
            orange: "#F76B15",
            yellow: "#FFC53D",
            green: "#30A46C",
            blue: "#0090FF",
            purple: "#8E4EC6",
            white: "#FFFFFF",
            black: "#111111"
        })
    readonly property var colors: Object.keys(palette)
    readonly property var tools: ["select", "pen", "highlighter", "line", "arrow", "rect", "ellipse", "text", "counter", "pixelate"]
    readonly property var toolKeys: ({
            select: "V",
            pen: "P",
            highlighter: "H",
            line: "L",
            arrow: "A",
            rect: "R",
            ellipse: "E",
            text: "T",
            counter: "N",
            pixelate: "M"
        })
    readonly property var toolIcons: ({
            select: "arrow_selector_tool",
            pen: "brush",
            highlighter: "ink_highlighter",
            line: "horizontal_rule",
            arrow: "arrow_outward",
            rect: "rectangle",
            ellipse: "circle",
            text: "title",
            counter: "counter_1",
            pixelate: "blur_on"
        })

    function stamp(): var {
        const d = new Date();
        const p = n => String(n).padStart(2, "0");
        return {
            date: `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`,
            time: `${p(d.getHours())}-${p(d.getMinutes())}-${p(d.getSeconds())}`
        };
    }

    // File name from the `fileName` template ({date}, {time}), no slash.
    function nextName(): string {
        const s = stamp();
        return `${fileName.replace(/\{date\}/g, s.date).replace(/\{time\}/g, s.time).replace(/\//g, "-")}.png`;
    }

    function cacheFile(): string {
        return `${cacheDir}/${nextName()}`;
    }

    function focusedScreen(): string {
        return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
    }

    // --- Entry points ---

    function region(): void {
        if (busy || active)
            return;
        busy = true;
        const names = Quickshell.screens.map(s => s.name);
        // A new name each time: images are cached by path.
        const id = Date.now();
        const paths = {};
        for (const n of names)
            paths[n] = `${cacheDir}/still-${n}-${id}.png`;
        stills = paths;
        // Geometry (JSON on stdout), then one grim per screen in parallel.
        const grims = names.map(n => `grim -l 0 -o '${n}' '${paths[n]}' &`).join(" ");
        freeze.command = ["sh", "-c", `mkdir -p "$1" && chmod 700 "$1" && rm -f "$1"/still-*.png && printf '{"monitors":' && hyprctl -j monitors && printf ',"clients":' && hyprctl -j clients && printf '}' && ${grims} wait`, "sh", cacheDir];
        freeze.running = true;
    }

    function screen(): void {
        if (busy || active)
            return;
        busy = true;
        const file = cacheFile();
        shoot.command = ["sh", "-c", `mkdir -p "$1" && grim -o "$2" "$3"`, "sh", cacheDir, focusedScreen(), file];
        shoot.file = file;
        shoot.running = true;
    }

    function window(): void {
        if (busy || active)
            return;
        busy = true;
        const file = cacheFile();
        // The active window's box, from hyprctl.
        shoot.command = ["sh", "-c", `mkdir -p "$1" && g=$(hyprctl -j activewindow | python3 -I -c 'import json,sys; w=json.load(sys.stdin); print("%d,%d %dx%d" % (*w["at"], *w["size"])) if w.get("at") else sys.exit(1)') && grim -g "$g" "$2"`, "sh", cacheDir, file];
        shoot.file = file;
        shoot.running = true;
    }

    function edit(path: string): void {
        if (busy || active || !path)
            return;
        Quickshell.execDetached(["mkdir", "-p", cacheDir]);
        file = path;
        screenName = focusedScreen();
        mode = "file";
    }

    function close(): void {
        mode = "";
        busy = false;
    }

    // --- Results ---

    // A shot written to `path` (cache): copy and/or save it, then notify.
    // action: "copy" | "save" | "both"
    function deliver(path: string, action: string): void {
        const copy = action !== "save";
        const save = action !== "copy";
        deliverer.path = path;
        deliverer.command = ["sh", "-c", `
            set -e
            out=""
            if [ "$3" = 1 ]; then
                d="$4"
                [ -n "$d" ] || d="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots"
                case "$d" in "~"*) d="$HOME\${d#"~"}" ;; esac
                mkdir -p "$d"
                out="$d/$(basename "$1")"
                cp "$1" "$out"
            fi
            if [ "$2" = 1 ]; then wl-copy --type image/png < "$1"; fi
            printf '%s' "$out"`, "sh", path, copy ? "1" : "0", save ? "1" : "0", dir];
        deliverer.running = true;
    }

    // --- Processes ---

    Process {
        id: freeze

        stdout: StdioCollector {
            id: geometry
        }

        onExited: code => {
            if (code !== 0) {
                root.busy = false;
                console.warn(`screenshot: freeze failed (${code})`);
                return;
            }
            try {
                root.windows = root.layout(JSON.parse(geometry.text));
            } catch (e) {
                root.windows = {};
            }
            root.screenName = root.focusedScreen();
            root.mode = "freeze";
            root.busy = false;
        }
    }

    // Windows shown on each monitor, in the monitor's coordinates, topmost
    // first: special workspace, fullscreen, floating, then by focus order.
    function layout(data: var): var {
        const out = {};
        for (const m of data.monitors ?? []) {
            const special = m.specialWorkspace?.name ?? "";
            const shown = (data.clients ?? []).filter(c => c.mapped !== false && !c.hidden && (c.workspace?.id === m.activeWorkspace?.id || (special && c.workspace?.name === special)));
            const rank = c => (special && c.workspace?.name === special ? 0 : 4) + (c.fullscreen ? 0 : 2) + (c.floating ? 0 : 1);
            shown.sort((a, b) => rank(a) - rank(b) || a.focusHistoryID - b.focusHistoryID);
            out[m.name] = shown.map(c => ({
                        x: c.at[0] - m.x,
                        y: c.at[1] - m.y,
                        w: c.size[0],
                        h: c.size[1],
                        title: c.title ?? "",
                        cls: c.class ?? ""
                    }));
        }
        return out;
    }

    Process {
        id: shoot

        property string file

        onExited: code => {
            root.busy = false;
            if (code === 0)
                root.deliver(file, "copy");
            else
                Quickshell.execDetached(["notify-send", "-a", "lc-shell", "-u", "critical", I18n.tr("shot.title"), I18n.tr("shot.failed")]);
        }
    }

    Process {
        id: deliverer

        property string path

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.notify)
                    return;
                notice.path = deliverer.path;
                notice.savedTo = text.trim();
                notice.running = false;
                notice.running = true;
            }
        }
        onExited: code => {
            if (code !== 0)
                Quickshell.execDetached(["notify-send", "-a", "lc-shell", "-u", "critical", I18n.tr("shot.title"), I18n.tr("shot.failed")]);
        }
    }

    // Notification with actions; notify-send prints the chosen one.
    Process {
        id: notice

        property string path
        property string savedTo

        command: {
            const actions = [`--action=edit=${I18n.tr("shot.annotate")}`];
            if (savedTo)
                actions.push(`--action=open=${I18n.tr("shot.open")}`, `--action=folder=${I18n.tr("shot.folder")}`);
            else
                actions.push(`--action=save=${I18n.tr("shot.save")}`);
            const body = savedTo ? I18n.tr("shot.savedTo", { path: savedTo.replace(Quickshell.env("HOME"), "~") }) : I18n.tr("shot.copied");
            return ["notify-send", "-a", "lc-shell", "-i", path, "-h", `string:image-path:${path}`, ...actions, I18n.tr("shot.title"), body];
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const action = text.trim();
                const target = notice.savedTo || notice.path;
                if (action === "edit")
                    root.edit(target);
                else if (action === "save")
                    root.deliver(notice.path, "save");
                else if (action === "open")
                    Qt.openUrlExternally(`file://${target}`);
                else if (action === "folder")
                    Qt.openUrlExternally(`file://${target.replace(/\/[^/]*$/, "")}`);
            }
        }
    }
}
