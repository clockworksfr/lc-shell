import QtQuick
import Quickshell
import qs.launcher
import qs.modules.bar
import qs.modules.launcher
import qs.modules.osd
import qs.services
import qs.theme

// Everything that lives on one screen: its profile (mode, theme, touch),
// and the windows its mode enables.
Scope {
    id: root

    required property ShellScreen modelData

    readonly property var profile: Config.forScreen(modelData)
    readonly property bool normal: profile.mode === "normal"
    readonly property var theme: Themes.resolve(profile.theme ?? Themes.themeFor(profile.mode), profile.touch)
    readonly property bool fullscreen: Screens.hasFullscreen(modelData.name)
    readonly property var barLook: Object.assign({}, theme.bar, profile.bar ?? {})

    LazyLoader {
        active: root.normal && !!root.profile.bar && ShellState.barVisible

        Bar {
            screen: root.modelData
            config: root.profile.bar
            theme: root.theme
        }
    }

    LazyLoader {
        active: root.normal && root.barLook.screenCorners > 0 && !root.fullscreen

        ScreenCorners {
            screen: root.modelData
            theme: root.theme
            radius: root.barLook.screenCorners
        }
    }

    // Automatic popup: never over a fullscreen window (see Screens.popupTarget).
    LazyLoader {
        active: !!root.profile.osd && Osd.shown && Osd.screenName === root.modelData.name && !root.fullscreen

        OsdWindow {
            screen: root.modelData
            config: root.profile.osd
            theme: root.theme
        }
    }

    // Opened explicitly by the user: allowed even over a fullscreen window.
    LazyLoader {
        active: Launcher.opened && Launcher.screenName === root.modelData.name

        LauncherWindow {
            screen: root.modelData
            theme: root.theme
        }
    }
}
