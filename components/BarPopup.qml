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
    // Grows out of the bar: reaches over its inner border (hidden at the
    // junction), same fill and border as the bar / island.
    readonly property int gap: 0
    readonly property real fillet: theme.drawer.fillet
    readonly property real overlap: Math.max(1, bar?.look?.border ?? 0)

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
        slide.duration = Motion.ms(theme, "base", bar?.screen?.name ?? "");
        slide.easing.type = Motion.easing(theme);
        slide.easing.overshoot = Motion.overshoot(theme);
        slide.restart();
    }

    // Slides back into the bar, then hides.
    function close(): void {
        if (!visible || (slide.running && slide.to === 0))
            return;
        // From the current value (interruptible), faster, no bounce.
        slide.to = 0;
        slide.duration = Motion.exitMs(theme, "base", bar?.screen?.name ?? "");
        slide.easing.type = Easing.InCubic;
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
            across = edge === "left" ? ox + bar.width - overlap : scr.width - ox - overlap;
        } else {
            along = clamp(ox + p.x + anchorItem.width / 2 - implicitWidth / 2, implicitWidth, scr.width);
            across = edge === "top" ? oy + bar.height - overlap : scr.height - oy - overlap;
        }
        // Tell the bar where the drawer hangs (its island grows to carry it).
        const start = along - (sideways ? oy : ox);
        bar.drawerSpan = { slot: anchorItem.parent?.parent ?? null, start: start, end: start + (sideways ? implicitHeight : implicitWidth) };
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
    implicitWidth: column.implicitWidth + theme.space.m * 2 + (sideways ? overlap : fillet * 2)
    implicitHeight: column.implicitHeight + theme.space.m * 2 + (sideways ? fillet * 2 : overlap)
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
        onFinished: {
            if (to === 0) {
                root.visible = false;
                if (root.bar)
                    root.bar.drawerSpan = null;
            }
        }
    }

    DrawerFrame {
        id: drawer

        anchors.fill: parent
        edge: root.edge
        fillet: root.fillet
        overlap: root.overlap
        // Opaque: a panel must stay readable (the island is at most a hair lighter).
        color: root.theme.color.surface
        lineWidth: root.bar?.look?.border ?? 0

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: root.theme.space.m
            spacing: root.theme.space.s
        }
    }
}
