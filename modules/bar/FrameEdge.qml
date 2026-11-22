import QtQuick
import Quickshell
import Quickshell.Wayland

// Invisible strip reserving a frame side's thickness, so windows stay
// inside the frame. Click-through.
PanelWindow {
    id: win

    // "top" | "bottom" | "left" | "right"
    property string edge: "top"
    property int thickness: 0

    readonly property bool vertical: edge === "left" || edge === "right"

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    implicitWidth: vertical ? thickness : 0
    implicitHeight: vertical ? 0 : thickness
    exclusiveZone: thickness
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "lc-frame-edge"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}
}
