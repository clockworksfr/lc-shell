pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.i18n

// Screenshots (grim, slurp, swappy):
// - region(): the screens freeze (each shows a still of itself, Freeze
//   windows), slurp picks a zone, grim takes it from the still;
// - screen(): the focused screen.
// The shot is copied to the clipboard and kept in the cache; a
// notification offers Open (swappy) and Save (Pictures/Screenshots).
Singleton {
    id: root

    // Screens showing their still while a zone is picked.
    property bool freezing: false
    // screen name -> still image path
    property var stills: ({})
    property bool busy: false

    readonly property string cacheDir: `${Quickshell.cachePath("screenshots")}`

    function stamp(): string {
        const d = new Date();
        const p = n => String(n).padStart(2, "0");
        return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
    }

    function region(): void {
        if (busy)
            return;
        busy = true;
        const names = Quickshell.screens.map(s => s.name);
        const paths = {};
        for (const n of names)
            paths[n] = `${cacheDir}/still-${n}.png`;
        stills = paths;
        // One grim per screen, then show the stills, then slurp.
        freezeShot.command = ["sh", "-c", `mkdir -p '${cacheDir}' && ${names.map(n => `grim -l 0 -o '${n}' '${paths[n]}'`).join(" && ")}`];
        freezeShot.running = true;
    }

    function screen(): void {
        if (busy)
            return;
        busy = true;
        const output = Hyprland.focusedMonitor?.name ?? "";
        const file = `${cacheDir}/${stamp()}.png`;
        take.file = file;
        take.command = ["sh", "-c", `mkdir -p '${cacheDir}' && grim -o "$1" "$2" && wl-copy < "$2"`, "sh", output, file];
        take.running = true;
    }

    Process {
        id: freezeShot
        onExited: code => {
            if (code !== 0) {
                root.busy = false;
                return;
            }
            root.freezing = true;
            // Let the stills map before slurp draws over them.
            pick.start();
        }
    }

    Timer {
        id: pick
        interval: 150
        onTriggered: picker.running = true
    }

    // slurp's geometry, then grim of that zone (from the stills on screen).
    Process {
        id: picker
        command: ["slurp", "-d"]
        stdout: StdioCollector {
            onStreamFinished: {
                const geometry = text.trim();
                if (!geometry) {
                    root.freezing = false;
                    root.busy = false;
                    return;
                }
                const file = `${root.cacheDir}/${root.stamp()}.png`;
                take.file = file;
                take.command = ["sh", "-c", `grim -l 0 -g "$1" "$2" && wl-copy < "$2"`, "sh", geometry, file];
                take.running = true;
            }
        }
        onExited: code => {
            if (code !== 0) {
                root.freezing = false;
                root.busy = false;
            }
        }
    }

    Process {
        id: take

        property string file

        onExited: code => {
            root.freezing = false;
            root.busy = false;
            if (code === 0) {
                notice.file = file;
                notice.running = true;
            }
        }
    }

    // Notification with actions; notify-send prints the chosen one.
    Process {
        id: notice

        property string file

        command: ["notify-send", "-a", "lc-shell", "-i", file, "-h", `string:image-path:${file}`, `--action=open=${I18n.tr("shot.open")}`, `--action=save=${I18n.tr("shot.save")}`, I18n.tr("shot.title"), I18n.tr("shot.copied")]
        stdout: StdioCollector {
            onStreamFinished: {
                const action = text.trim();
                if (action === "open")
                    Quickshell.execDetached(["swappy", "-f", notice.file]);
                else if (action === "save")
                    Quickshell.execDetached(["sh", "-c", "dir=\"$(xdg-user-dir PICTURES 2>/dev/null || echo \"$HOME/Pictures\")/Screenshots\"; mkdir -p \"$dir\" && cp \"$1\" \"$dir/$(basename \"$1\")\" && notify-send -a lc-shell \"$2\" \"$dir/$(basename \"$1\")\"", "sh", notice.file, I18n.tr("shot.saved")]);
            }
        }
    }
}
