// lc-shell entry point. Launch with: qs -c lc
//@ pragma IconTheme Papirus-Dark
import Quickshell
import qs.launcher
import qs.modules
import qs.services

ShellRoot {
    // One scope per screen. Screens come and go at runtime (eGPU hotplug),
    // Variants creates and destroys the matching scopes automatically.
    Variants {
        model: Quickshell.screens

        ScreenScope {}
    }

    Ipc {}
    LauncherIpc {}
}
