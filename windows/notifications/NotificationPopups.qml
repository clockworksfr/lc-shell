import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.panels
import qs.services
import qs.theme

// Notification popups on the target screen, at the configured position
// (settings notifications.position: "top-right" by default, "top-left",
// "top-center", "bottom-right", "bottom-left", "bottom-center"), clear of
// the bar. At the bottom the newest is nearest the edge.
// Only as large as the stack: the rest of the screen stays clickable.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    property string position: "top-right"
    // Room taken by the bar (and frame) on each edge.
    property var edgeOffsets: ({ top: 0, bottom: 0, left: 0, right: 0 })

    readonly property bool atBottom: position.startsWith("bottom")
    readonly property string side: position.endsWith("left") ? "left" : position.endsWith("right") ? "right" : "center"

    readonly property int maxVisible: 5

    // Unanchored on both sides = centered by the compositor.
    anchors.top: !atBottom
    anchors.bottom: atBottom
    anchors.right: side === "right"
    anchors.left: side === "left"
    margins.top: atBottom ? 0 : edgeOffsets.top + theme.space.l
    margins.bottom: atBottom ? edgeOffsets.bottom + theme.space.l : 0
    margins.right: side === "right" ? edgeOffsets.right + theme.space.l : 0
    margins.left: side === "left" ? edgeOffsets.left + theme.space.l : 0

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
            model: win.atBottom ? NotificationCenter.popups.slice(0, win.maxVisible).reverse() : NotificationCenter.popups.slice(0, win.maxVisible)

            NotificationCard {
                required property var modelData
                entry: modelData
                popup: true
            }
        }
    }
}
