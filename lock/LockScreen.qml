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

        // Lock surfaces aren't Quickshell windows: QsWindow.window is null in
        // them, so everything inside takes Themes.fallback, the normal
        // screens' theme (same here, for the surface's own color).
        color: Themes.fallback.color.bg

        LockContent {
            anchors.fill: parent
            screen: surface.screen
        }

        Component.onCompleted: Lock.surfacesShown()
    }
}
