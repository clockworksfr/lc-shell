// lc-shell entry point. Launch with: qs -c lc
//@ pragma IconTheme Papirus-Dark
import QtQuick
import Quickshell
import qs.dashboard
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

    // Singletons are lazy: touch the window placer so it starts.
    Component.onCompleted: CellTiler.managed
}
