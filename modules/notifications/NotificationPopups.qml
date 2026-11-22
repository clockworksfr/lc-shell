import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.panels
import qs.services
import qs.theme

// Notification popups, top-right of the target screen, below its bar.
// Only as large as the stack: the rest of the screen stays clickable.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    // Distance from the top edge (keeps clear of the bar).
    property int topOffset: 0

    readonly property int maxVisible: 5

    anchors.top: true
    anchors.right: true
    margins.top: topOffset
    margins.right: theme.space.l

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
