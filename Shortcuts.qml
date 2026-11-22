import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.clipboard
import qs.launcher
import qs.lock
import qs.theme
import qs.services
import qs.settings

// Hyprland global shortcuts (instant, no process spawned), bound in the
// Hyprland config with the "global" dispatcher, e.g. in Lua:
//   hl.bind("SUPER + Space", hl.dsp.global("lc:launcher"))
// Same actions as the IPC targets (qs -c lc ipc call …).
Scope {
    GlobalShortcut {
        appid: "lc"
        name: "launcher"
        description: "Open or close the launcher"
        onPressed: Launcher.toggle()
    }

    GlobalShortcut {
        appid: "lc"
        name: "emoji"
        description: "Launcher on emoji search"
        onPressed: Launcher.open(":")
    }

    GlobalShortcut {
        appid: "lc"
        name: "files"
        description: "Launcher on file search"
        onPressed: Launcher.open("/")
    }

    GlobalShortcut {
        appid: "lc"
        name: "settings"
        description: "Open or close the settings"
        onPressed: Settings.toggle()
    }

    GlobalShortcut {
        appid: "lc"
        name: "editBar"
        description: "Edit the bar"
        onPressed: ShellState.editing = !ShellState.editing
    }

    GlobalShortcut {
        appid: "lc"
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: NotificationCenter.clearAll()
    }

    GlobalShortcut {
        appid: "lc"
        name: "dnd"
        description: "Toggle do not disturb"
        onPressed: NotificationCenter.setDnd(!NotificationCenter.dnd)
    }

    GlobalShortcut {
        appid: "lc"
        name: "clipboard"
        description: "Clipboard manager"
        onPressed: Clipboard.toggle()
    }

    GlobalShortcut {
        appid: "lc"
        name: "clipboardIncognito"
        description: "Clipboard: pause / resume recording"
        onPressed: Clipboard.setPaused(!Clipboard.paused)
    }

    GlobalShortcut {
        appid: "lc"
        name: "screenshot"
        description: "Screenshot of a zone (screens frozen)"
        onPressed: Screenshot.region()
    }

    GlobalShortcut {
        appid: "lc"
        name: "screenshotScreen"
        description: "Screenshot of the focused screen"
        onPressed: Screenshot.screen()
    }

    GlobalShortcut {
        appid: "lc"
        name: "notifications"
        description: "Notifications panel"
        onPressed: ShellState.panelRequested("notifications", "")
    }

    GlobalShortcut {
        appid: "lc"
        name: "media"
        description: "Media card (player, lyrics)"
        onPressed: ShellState.card?.visible ? ShellState.cardRequested("", "") : ShellState.cardRequested("media", "")
    }

    GlobalShortcut {
        appid: "lc"
        name: "toggleVariant"
        description: "Light / dark"
        onPressed: Themes.toggleVariant()
    }

    GlobalShortcut {
        appid: "lc"
        name: "nextTheme"
        description: "Next theme"
        onPressed: {
            const ids = Object.keys(Themes.definitions);
            const id = ids[(ids.indexOf(Themes.themeFor("normal")) + 1) % ids.length];
            Themes.setTheme("normal", id);
            Themes.setTheme("modules", id);
        }
    }

    GlobalShortcut {
        appid: "lc"
        name: "lock"
        description: "Lock the session"
        onPressed: Lock.lock()
    }
}
