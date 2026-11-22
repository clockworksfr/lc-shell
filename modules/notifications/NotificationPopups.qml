import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.panels
import qs.services
import qs.theme

// Notification popups, top-right of the target screen (top-left when the
// bar is on the right), clear of the bar.
// Only as large as the stack: the rest of the screen stays clickable.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    // "right" | "left"
    property string side: "right"
    // Distances from the edges (keep clear of the bar).
    property int topOffset: 0
    property int sideOffset: 0

    readonly property int maxVisible: 5

    anchors.top: true
    anchors.right: side === "right"
    anchors.left: side === "left"
    margins.top: topOffset
    margins.right: side === "right" ? sideOffset : 0
    margins.left: side === "left" ? sideOffset : 0

    implicitWidth: 400
    implicitHeight: stack.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        id: stack

        width: parent.width
        spacing: win.theme.space.s

        Repeater {
            model: NotificationCenter.popups.slice(0, win.maxVisible)

            NotificationCard {
                required property var modelData
                entry: modelData
                popup: true
            }
        }
    }
}
