import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components.dashboard
import qs.dashboard
import qs.dashboard.modules
import qs.i18n
import qs.services
import qs.theme

// The shell's lights panels, one of each: the full Hue module centered on
// a screen (Super+U where the bar has no lights widget, the modules' More)
// and the color panel (HueBridge.picker). In the theme of their screen
// (touch sizes on the modules screen).
Scope {
    id: root

    property ShellScreen target: null
    readonly property ShellScreen pickerScreen: HueBridge.picker ? (Quickshell.screens.find(s => s.name === HueBridge.picker.screen) ?? Quickshell.screens[0]) : null

    function themeOf(screen: ShellScreen): var {
        const profile = Config.forScreen(screen);
        return Themes.resolve(profile.theme ?? Themes.themeFor(profile.mode), profile.touch, profile.mode);
    }

    Connections {
        target: ShellState

        function onPanelRequested(type: string, screenName: string): void {
            if (type !== "lights")
                return;
            const name = screenName || Hyprland.focusedMonitor?.name || "";
            const handled = ShellState.slots.some(s => s.type === "lights" && s.visible && s.screen?.name === name);
            if (handled)
                return;
            root.target = root.target ? null : (Quickshell.screens.find(s => s.name === name) ?? null);
        }
    }

    // Reviews: opened over IPC, no grab.
    Connections {
        target: Showcase

        function onHuePanelChanged(): void {
            root.target = Quickshell.screens.find(s => s.name === Showcase.huePanel) ?? null;
        }
    }

    LazyLoader {
        active: !!root.target

        PanelWindow {
            id: panel

            readonly property var theme: root.themeOf(root.target)

            screen: root.target
            implicitWidth: Math.min((screen?.width ?? 1200) - 80, 1100)
            implicitHeight: Math.min((screen?.height ?? 700) - 40, 640)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lc-hue"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            // Off while the color panel is up (it takes the focus).
            HyprlandFocusGrab {
                active: !Showcase.huePanel && !HueBridge.picker
                windows: [panel]
                onCleared: root.target = null
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.target = null

                Hue {
                    anchors.fill: parent
                    full: true
                    options: ({ type: "hue" })
                }

                ModuleButton {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    icon: "close"
                    size: 44
                    onTapped: root.target = null
                }
            }
        }
    }

    // The color of a room or a light.
    LazyLoader {
        active: !!HueBridge.picker

        PanelWindow {
            id: pickerWindow

            readonly property var theme: root.themeOf(root.pickerScreen)
            readonly property var target: HueBridge.picker

            screen: root.pickerScreen
            implicitWidth: Math.min((screen?.width ?? 1600) - 80, 1100)
            implicitHeight: Math.min((screen?.height ?? 700) - 40, 520)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lc-hue-color"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                active: true
                windows: [pickerWindow]
                onCleared: HueBridge.picker = null
            }

            ModulePanel {
                anchors.fill: parent
                title: pickerWindow.target ? I18n.tr("hue.colorOf", { name: pickerWindow.target.name }) : ""
            }

            Item {
                anchors.fill: parent
                anchors.topMargin: 30
                focus: true
                Keys.onEscapePressed: HueBridge.picker = null

                HueColorPicker {
                    anchors.fill: parent
                    title: pickerWindow.target?.name ?? ""
                    current: pickerWindow.target?.kind === "light" ? (HueBridge.lights[pickerWindow.target.id]?.color || "#FFE9D2") : (HueBridge.room(pickerWindow.target?.id ?? "")?.color || "#FFE9D2")
                    onColorPicked: hex => pickerWindow.target.kind === "light" ? HueBridge.setLightColor(pickerWindow.target.id, hex) : HueBridge.setRoomColor(pickerWindow.target.id, hex)
                    onWhitePicked: kelvin => pickerWindow.target.kind === "light" ? HueBridge.setLightWhite(pickerWindow.target.id, kelvin) : HueBridge.setRoomWhite(pickerWindow.target.id, kelvin)
                }
            }

            ModuleButton {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                icon: "close"
                size: 44
                onTapped: HueBridge.picker = null
            }
        }
    }
}
