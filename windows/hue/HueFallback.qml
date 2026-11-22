import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components.dashboard
import qs.dashboard.modules
import qs.services
import qs.theme

// Super+U (`bar panel lights`) on a screen whose bar has no lights widget:
// the Hue module in a panel centered on that screen.
Scope {
    id: root

    property ShellScreen target: null

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

    LazyLoader {
        active: !!root.target

        PanelWindow {
            id: panel

            readonly property var theme: Themes.resolve(Themes.themeFor("normal"), false, "normal")

            screen: root.target
            implicitWidth: Math.min((screen?.width ?? 1200) - 80, 1000)
            implicitHeight: Math.min((screen?.height ?? 700) - 80, 560)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lc-hue"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                active: true
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
                    size: 40
                    onTapped: root.target = null
                }
            }
        }
    }
}
