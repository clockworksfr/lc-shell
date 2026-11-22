import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme

// Panel of a bar widget: a drawer coming out of the bar (attached to its
// inner edge, concave fillets, slides out and back), centered on the
// widget and kept on screen. A layer surface rather than a popup: popups of
// a bar only show while the bar has the pointer, which breaks panels opened
// from a key bind. Clicking outside closes it (Hyprland focus grab).
// Open/close with toggle(); children go into a Column.
PanelWindow {
    id: root

    required property Item anchorItem
    default property alias content: column.data

    readonly property var bar: anchorItem?.QsWindow.window ?? null
    // Same theme as the bar it opens from.
    readonly property var theme: bar?.theme ?? Themes.fallback
    readonly property string edge: bar?.edge ?? "top"
    readonly property bool sideways: edge === "left" || edge === "right"
    // Attached to the bar: no gap.
    readonly property int gap: 0
    readonly property real fillet: theme.radius.control

    // Offset along the bar (from the screen's left or top edge).
    property real along: 0
    // Distance from the bar's screen edge.
    property real across: 0

    function toggle(): void {
        if (visible) {
            close();
            return;
        }
        place();
        drawer.progress = 0;
        visible = true;
        slide.to = 1;
        slide.restart();
    }

    // Slides back into the bar, then hides.
    function close(): void {
        if (!visible || (slide.running && slide.to === 0))
            return;
        slide.to = 0;
        slide.restart();
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
        // Kept on screen (8 px from the edges).
        const clamp = (v, size, max) => Math.max(8, Math.min(v, max - size - 8));
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
    // The drawer body plus room for the fillets on both ends along the bar.
    implicitWidth: column.implicitWidth + theme.space.m * 2 + (sideways ? 0 : fillet * 2)
    implicitHeight: column.implicitHeight + theme.space.m * 2 + (sideways ? fillet * 2 : 0)
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
        onCleared: root.close()
    }

    NumberAnimation {
        id: slide
        target: drawer
        property: "progress"
        duration: root.theme.motion.duration + 40
        easing.type: Easing.OutCubic
        onFinished: if (to === 0) root.visible = false
    }

    DrawerFrame {
        id: drawer

        anchors.fill: parent
        edge: root.edge
        fillet: root.fillet

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: root.theme.space.m
            spacing: root.theme.space.s
        }
    }
}
