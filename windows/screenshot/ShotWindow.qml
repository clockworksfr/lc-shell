import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// The screenshot editor over one screen: a full-screen overlay; the
// screen holding the selection gets the keyboard.
PanelWindow {
    id: win

    property var theme: Themes.fallback

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-screenshot"
    WlrLayershell.keyboardFocus: editor.holder ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    ShotEditor {
        id: editor

        anchors.fill: parent
        theme: win.theme
        name: win.screen?.name ?? ""
    }
}
