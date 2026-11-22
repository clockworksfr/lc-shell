import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// The session lock (ext-session-lock): one surface per screen, each with
// its screen's theme.
WlSessionLock {
    id: sessionLock

    locked: Lock.locked

    WlSessionLockSurface {
        id: surface

        property var theme: Themes.resolve(Config.forScreen(screen).theme ?? Themes.themeFor(Config.forScreen(screen).mode), false, "normal")

        color: theme.color.bg

        LockContent {
            anchors.fill: parent
            screen: surface.screen
        }

        Component.onCompleted: Lock.surfacesShown()
    }
}
