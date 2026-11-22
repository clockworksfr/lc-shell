// lc-shell entry point. Launch with: qs -c lc
//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import qs.dashboard
import qs.i18n
import qs.launcher
import qs.modules
import qs.services
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

    // Singletons are lazy: touch the ones that must run from the start.
    Component.onCompleted: {
        CellTiler.managed;
        Fonts.files;
    }
}
