import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// A still of its screen while a screenshot zone is picked (the screen
// "freezes"): over everything, no input (slurp takes it).
PanelWindow {
    id: win

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "black"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-freeze"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    Image {
        anchors.fill: parent
        source: Screenshot.stills[win.screen?.name ?? ""] ? `file://${Screenshot.stills[win.screen.name]}` : ""
        cache: false
        fillMode: Image.Stretch
    }
}
