import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.clipboard
import qs.dashboard
import qs.launcher
import qs.windows.bar
import qs.windows.clipboard
import qs.windows.dashboard
import qs.windows.launcher
import qs.windows.notifications
import qs.windows.osd
import qs.windows.screenshot
import qs.windows.wallpaper
import qs.services
import qs.theme

// Everything that lives on one screen: its profile (mode, theme, touch),
// and the windows its mode enables.
Scope {
    id: root

    required property ShellScreen modelData

    readonly property var profile: Config.forScreen(modelData)
    readonly property bool normal: profile.mode === "normal"
    readonly property var theme: Themes.resolve(profile.theme ?? Themes.themeFor(profile.mode), profile.touch, profile.mode)
    readonly property bool fullscreen: Screens.hasFullscreen(modelData.name)
    readonly property var barLook: Object.assign({}, theme.bar, profile.bar ?? {})
    readonly property bool hasBar: normal && !!profile.bar && ShellState.barVisible
    readonly property string barEdge: ["top", "bottom", "left", "right"].includes(barLook.position) ? barLook.position : "top"
    readonly property int barThickness: barEdge === "left" || barEdge === "right" ? barLook.verticalWidth : barLook.height

    // Frame: theme defaults, overridden in settings by `frame: true|false`
    // or an object. The bar is its thick side.
    readonly property var frame: {
        const base = theme.bar.frame ?? {};
        const over = profile.bar?.frame;
        if (over === undefined || over === null)
            return base;
        return typeof over === "object" ? Object.assign({}, base, over) : Object.assign({}, base, { enabled: !!over });
    }
    readonly property bool framed: hasBar && !!frame.enabled
    readonly property var frameSides: {
        const sides = {};
        for (const edge of ["top", "bottom", "left", "right"]) {
            const t = frame.thickness;
            sides[edge] = edge === barEdge ? barThickness : (typeof t === "object" ? (t[edge] ?? 0) : (t ?? 0));
        }
        return sides;
    }
    readonly property int cornerRadius: barLook.screenCorners > 0 ? barLook.screenCorners : framed ? Math.min(frame.innerRadius + (frame.thickness?.top ?? frame.thickness ?? 0), 32) : 0

    // Room taken from an edge by the bar (and the frame), for popups.
    function barExtent(edge: string): int {
        if (framed)
            return frameSides[edge];
        if (!hasBar || edge !== barEdge)
            return 0;
        return barThickness + (barLook.floating ? barLook.margin : 0);
    }

    LazyLoader {
        active: Wallpaper.enabled

        WallpaperWindow {
            screen: root.modelData
            theme: root.theme
            source: Wallpaper.pathFor(root.modelData)
        }
    }

    LazyLoader {
        active: root.normal && !!root.profile.bar && ShellState.barVisible

        Bar {
            screen: root.modelData
            config: BarEditor.barConfig(root.modelData, root.profile.bar)
            theme: root.theme
            framed: root.framed
        }
    }

    // Bar edit mode toolbar.
    LazyLoader {
        active: ShellState.editing && root.hasBar

        EditToolbar {
            screen: root.modelData
            theme: root.theme
            barEdge: root.barEdge === "bottom" ? "bottom" : "top"
            barExtent: root.barEdge === "top" || root.barEdge === "bottom" ? root.barExtent(root.barEdge) : 0
        }
    }

    // Frame: drawing + reservation of the sides other than the bar's.
    // Gone while a fullscreen window is shown.
    LazyLoader {
        active: root.framed && !root.fullscreen

        Scope {
            FrameWindow {
                screen: root.modelData
                theme: root.theme
                sides: root.frameSides
                innerRadius: root.frame.innerRadius
                outline: root.frame.outline
                fillOpacity: root.barLook.opacity
            }

            Variants {
                model: ["top", "bottom", "left", "right"].filter(edge => edge !== root.barEdge && root.frameSides[edge] > 0)

                FrameEdge {
                    required property string modelData
                    screen: root.modelData
                    edge: modelData
                    thickness: root.frameSides[modelData]
                }
            }
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

    // Screenshot of a zone: the screen shows a still of itself meanwhile.
    LazyLoader {
        active: Screenshot.freezing

        FreezeWindow {
            screen: root.modelData
        }
    }

    // "Bar saved · Undo" after the bar's edit mode, on the focused screen.
    LazyLoader {
        active: BarEditor.toastUntil > 0 && root.modelData.name === (Hyprland.focusedMonitor?.name ?? "")

        EditToast {
            screen: root.modelData
            theme: root.theme
        }
    }

    // Dashboard editor (opened explicitly: allowed over a fullscreen window).
    LazyLoader {
        active: DashboardEditor.editing && DashboardEditor.screenName === root.modelData.name

        DashboardEditorWindow {
            screen: root.modelData
            theme: root.theme
        }
    }

    LazyLoader {
        active: root.normal && root.cornerRadius > 0 && !root.fullscreen

        ScreenCorners {
            screen: root.modelData
            theme: root.theme
            radius: root.cornerRadius
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
            position: Config.get("notifications.position") ?? "top-right"
            edgeOffsets: ({ top: root.barExtent("top"), bottom: root.barExtent("bottom"), left: root.barExtent("left"), right: root.barExtent("right") })
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

    // Clipboard manager: explicit too.
    LazyLoader {
        active: Clipboard.opened && Clipboard.screenName === root.modelData.name

        ClipboardWindow {
            screen: root.modelData
            theme: root.theme
            edgeOffsets: ({ top: root.barExtent("top"), bottom: root.barExtent("bottom"), left: root.barExtent("left"), right: root.barExtent("right") })
        }
    }
}
