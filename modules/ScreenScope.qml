import QtQuick
import Quickshell
import qs.launcher
import qs.modules.bar
import qs.modules.dashboard
import qs.modules.launcher
import qs.modules.notifications
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
    readonly property bool hasBar: normal && !!profile.bar && ShellState.barVisible
    readonly property string barEdge: ["top", "bottom", "left", "right"].includes(barLook.position) ? barLook.position : "top"
    // Room the bar takes from its edge (0 on the other edges).
    function barExtent(edge: string): int {
        if (!hasBar || edge !== barEdge)
            return 0;
        const vertical = barEdge === "left" || barEdge === "right";
        return (vertical ? barLook.verticalWidth : barLook.height) + (barLook.floating ? barLook.margin : 0);
    }

    LazyLoader {
        active: root.normal && !!root.profile.bar && ShellState.barVisible

        Bar {
            screen: root.modelData
            config: root.profile.bar
            theme: root.theme
        }
    }

    LazyLoader {
        active: root.profile.mode === "modules" && !!root.profile.dashboard

        DashboardWindow {
            screen: root.modelData
            config: root.profile.dashboard
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
            edgeOffset: root.barExtent(config?.position === "top" ? "top" : "bottom")
        }
    }

    // Automatic popups: same rule as the OSD.
    LazyLoader {
        active: NotificationCenter.popups.length > 0 && NotificationCenter.popupScreen === root.modelData.name && !root.fullscreen

        NotificationPopups {
            screen: root.modelData
            theme: root.theme
            // Right side, or left when the bar is on the right; clear of the bar.
            side: root.barEdge === "right" ? "left" : "right"
            topOffset: root.barExtent("top") + root.theme.space.l
            sideOffset: root.barExtent(side) + root.theme.space.l
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
