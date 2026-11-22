// lc-shell entry point. Launch with: qs -c lc
//@ pragma IconTheme Papirus-Dark
// Tray menus are platform menus: they need a QApplication.
//@ pragma UseQApplication
// Animations on a timer, not on the windows' frames: with Qt's default
// driver, a window redrawn 30 times a second (the dashboard's spectrum,
// fed by cava at 30 fps) paced every animation of the shell at 30 fps,
// bar drawers on the 120 Hz screen included (measured: 33 ms → 9.6 ms a
// tick).
//@ pragma Env QSG_USE_SIMPLE_ANIMATION_DRIVER=1
import QtQuick
import Quickshell
import qs.clipboard
import qs.dashboard
import qs.i18n
import qs.launcher
import qs.lock
import qs.windows
import qs.windows.hue
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
    DashboardIpc {}
    Shortcuts {}
    HueFallback {}
    ThemeIpc {}
    I18nIpc {}
    SettingsIpc {}
    LockIpc {}
    ClipboardIpc {}

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
        Clipboard.count;
        HyprBorders.enabled;
        HyprRules.applied;
    }
}
