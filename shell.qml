// lc-shell entry point. Launch with: qs -c lc
//@ pragma IconTheme Papirus-Dark
// Tray menus are platform menus: they need a QApplication.
//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.dashboard
import qs.i18n
import qs.launcher
import qs.lock
import qs.windows
import qs.services
import qs.settings
import qs.theme

ShellRoot {
    // One scope per screen. Screens come and go at runtime (eGPU hotplug),
    // Variants creates and destroys the matching scopes automatically.
    Variants {
        model: Quickshell.screens

        ScreenScope {}
    }

    Ipc {}
    LauncherIpc {}
    ThemeIpc {}
    I18nIpc {}
    SettingsIpc {}
    LockIpc {}

    // Locks only when Lock.locked is set (idle, logind, IPC).
    LockScreen {}

    LazyLoader {
        active: Lock.previewing

        LockPreview {
            visible: true
        }
    }

    LazyLoader {
        active: Settings.opened

        SettingsWindow {
            visible: true
        }
    }

    // Singletons are lazy: touch the ones that must run from the start.
    Component.onCompleted: {
        CellTiler.managed;
        Fonts.files;
        NotificationCenter.dnd;
        Idle.enabled;
    }
}
