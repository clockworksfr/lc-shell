import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
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
    // Panels are hidden rather than destroyed (the grab off first): the
    // keyboard goes back to the window it came from. Last screens kept.
    property ShellScreen panelScreen: null
    property ShellScreen colorScreen: null
    onTargetChanged: {
        if (target)
            panelScreen = target;
        else
            Qt.callLater(ShellState.restoreFocus);
    }
    onPickerScreenChanged: if (pickerScreen) colorScreen = pickerScreen
    property var lastPicker: null
    Connections {
        target: HueBridge
        function onPickerChanged(): void {
            if (HueBridge.picker)
                root.lastPicker = HueBridge.picker;
            else if (!root.target)
                Qt.callLater(ShellState.restoreFocus);
        }
    }

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
        active: !!root.panelScreen

        PanelWindow {
            id: panel

            readonly property var theme: root.themeOf(root.panelScreen)

            visible: !!root.target
            screen: root.panelScreen
            implicitWidth: Math.min((screen?.width ?? 1200) - 80, 1100)
            implicitHeight: Math.min((screen?.height ?? 700) - 40, 640)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lc-hue"
            WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            // Off while the color panel is up (it takes the focus).
            HyprlandFocusGrab {
                active: panel.visible && !Showcase.huePanel && !HueBridge.picker
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

                WindowBorder {
                    radius: panel.theme.style.module === "matrix" ? 28 : panel.theme.radius.card
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
        active: !!root.colorScreen

        PanelWindow {
            id: pickerWindow

            readonly property var theme: root.themeOf(root.colorScreen)
            readonly property var target: HueBridge.picker ?? root.lastPicker

            visible: !!HueBridge.picker
            screen: root.colorScreen
            implicitWidth: Math.min((screen?.width ?? 1600) - 80, 1100)
            implicitHeight: Math.min((screen?.height ?? 700) - 40, 520)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lc-hue-color"
            WlrLayershell.keyboardFocus: pickerWindow.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                active: pickerWindow.visible
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

            WindowBorder {
                radius: pickerWindow.theme.style.module === "matrix" ? 28 : pickerWindow.theme.radius.card
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
