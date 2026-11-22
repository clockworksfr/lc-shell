import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.i18n
import qs.theme

// The lock screen in a centered panel: check its look and the PAM password
// check without locking anything. The keyboard goes to it only when the
// password field is clicked (no stray keystrokes sent to PAM).
// Close: ×, Escape (once focused), or `lock closePreview`.
PanelWindow {
    id: win

    property var theme: Themes.resolve(Themes.themeFor("normal"), false, "normal")

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    implicitWidth: Math.min(1280, (screen?.width ?? 1400) - 64)
    implicitHeight: Math.min(800, (screen?.height ?? 900) - 96)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lc-lock-preview"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Component.onCompleted: screen = screen

    Rectangle {
        anchors.fill: parent
        radius: win.theme.radius.panel
        color: win.theme.color.bg
        clip: true
        Keys.onEscapePressed: Lock.previewing = false

        LockContent {
            anchors.fill: parent
            screen: win.screen
            preview: true
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: win.theme.space.s
            width: 32
            height: 32
            radius: 16
            color: closeArea.containsMouse ? win.theme.color.surface3 : win.theme.color.surface

            Icon {
                anchors.centerIn: parent
                name: "close"
                size: 20
            }

            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Lock.previewing = false
            }
        }
    }
}
