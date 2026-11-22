import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.launcher
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
}
