import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme

// Panel opened from a bar block, toward the inside of the screen, past the
// bar's inner edge, centered on the block (kept on screen). A layer
// surface rather than a popup: popups of a bar only show while the bar has
// the pointer, which breaks panels opened from a key bind. Clicking outside
// closes it (Hyprland focus grab). Open/close with toggle(); children go
// into a Column.
PanelWindow {
    id: root

    required property Item anchorItem
    default property alias content: column.data

    readonly property var bar: anchorItem?.QsWindow.window ?? null
    // Same theme as the bar it opens from.
    readonly property var theme: bar?.theme ?? Themes.fallback
    readonly property string edge: bar?.edge ?? "top"
    readonly property bool sideways: edge === "left" || edge === "right"
    readonly property int gap: theme.space.s

    // Offset along the bar (from the screen's left or top edge).
    property real along: 0
    // Distance from the bar's screen edge.
    property real across: 0

    function toggle(): void {
        if (visible) {
            visible = false;
            return;
        }
        place();
        visible = true;
    }

    function place(): void {
        if (!bar)
            return;
        const scr = bar.screen;
        const p = anchorItem.mapToItem(bar.contentItem, 0, 0);
        // Bar window origin on its screen.
        const o = bar.origin();
        const ox = o.x;
        const oy = o.y;
        const clamp = (v, size, max) => Math.max(gap, Math.min(v, max - size - gap));
        if (sideways) {
            along = clamp(oy + p.y + anchorItem.height / 2 - implicitHeight / 2, implicitHeight, scr.height);
            across = edge === "left" ? ox + bar.width + gap : scr.width - ox + gap;
        } else {
            along = clamp(ox + p.x + anchorItem.width / 2 - implicitWidth / 2, implicitWidth, scr.width);
            across = edge === "top" ? oy + bar.height + gap : scr.height - oy + gap;
        }
    }

    screen: bar?.screen ?? null
    anchors {
        top: edge !== "bottom"
        bottom: edge === "bottom"
        left: edge !== "right"
        right: edge === "right"
    }
    margins {
        top: edge === "top" ? across : sideways ? along : 0
        bottom: edge === "bottom" ? across : 0
        left: edge === "left" ? across : !sideways ? along : 0
        right: edge === "right" ? across : 0
    }

    visible: false
    color: "transparent"
    implicitWidth: column.implicitWidth + theme.space.m * 2
    implicitHeight: column.implicitHeight + theme.space.m * 2
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-panel"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Re-center when the content changes size (lists loading…).
    onImplicitWidthChanged: if (visible) place()
    onImplicitHeightChanged: if (visible) place()

    HyprlandFocusGrab {
        active: root.visible
        // The bar stays usable: clicking the block again toggles the panel.
        windows: root.bar ? [root, root.bar] : [root]
        onCleared: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radius.panel
        color: root.theme.color.surface
        border.width: root.theme.border.width
        border.color: root.theme.color.line

        Glass {}

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: root.theme.space.m
            spacing: root.theme.space.s
        }
    }
}
