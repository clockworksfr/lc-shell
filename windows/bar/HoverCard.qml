import QtQuick
import Quickshell
import qs.cards
import qs.components
import qs.services
import qs.theme

// The bar's hover card: one per bar, moved from widget to widget. A drawer
// attached to the bar (fillets, slides out), centered on the widget,
// doesn't take the keyboard. Content comes from cards/<Type>Card.qml.
PopupWindow {
    id: root

    required property var host
    // WidgetSlot the card is shown for.
    property Item slot: null
    readonly property bool hovered: hover.hovered

    readonly property var theme: host?.theme ?? Themes.fallback
    // A drawer attached to the bar (no gap), with fillets on both ends.
    readonly property int gap: 0
    readonly property real fillet: theme.drawer.fillet
    // Reaches over the bar's inner border: no line at the junction.
    // +1: a popup's position is rounded; make sure the border line is covered.
    readonly property real overlap: Math.max(1, host?.look?.border ?? 0) + 1
    readonly property bool sideways: host?.edge === "left" || host?.edge === "right"
    // Fillets at each end (place(): 0 where the card continues its island).
    property real filletLow: fillet
    property real filletHigh: fillet

    function showFor(target: Item): void {
        if (visible && slot === target)
            return;
        const switching = visible;
        // A visible popup doesn't follow anchor changes: close it, then
        // re-anchor and reopen on the next event loop turn (hiding and
        // showing in the same turn is a no-op). Reads as a quick swap.
        visible = false;
        slot = target;
        Qt.callLater(() => {
            if (root.slot !== target)
                return;
            root.place();
            content.opacity = switching ? 0.4 : 1;
            frame.progress = switching ? 1 : 0;
            root.visible = true;
            if (switching) {
                swap.duration = Motion.ms(root.theme, "fast", root.host?.screen?.name ?? "");
                swap.restart();
            } else {
                appear.duration = Motion.ms(root.theme, "base", root.host?.screen?.name ?? "");
                appear.easing.type = Motion.easing(root.theme);
                appear.easing.overshoot = Motion.overshoot(root.theme);
                appear.restart();
            }
        });
    }

    function hide(): void {
        visible = false;
        slot = null;
        if (host && host.drawerSpan?.slot !== undefined)
            host.drawerSpan = null;
    }

    onVisibleChanged: ShellState.card = { visible: visible, type: slot?.type ?? "", screen: host?.screen?.name ?? "" }

    function place(): void {
        if (!slot || !host)
            return;
        // The anchor rect spans exactly the drawer along the bar: the popup,
        // centered on it, lands where drawerPlace() put it.
        const d = host.drawerPlace(slot, sideways ? bodyHeight : 380, fillet);
        filletLow = d.low;
        filletHigh = d.high;
        const span = d.end - d.start;
        let rect;
        let side;
        switch (host.edge) {
        case "bottom":
            rect = Qt.rect(d.start, overlap, span, 0);
            side = Edges.Top;
            break;
        case "left":
            rect = Qt.rect(host.width - overlap, d.start, 0, span);
            side = Edges.Right;
            break;
        case "right":
            rect = Qt.rect(overlap, d.start, 0, span);
            side = Edges.Left;
            break;
        default:
            rect = Qt.rect(d.start, host.height - overlap, span, 0);
            side = Edges.Bottom;
        }
        host.drawerSpan = { slot: slot, start: d.start, end: d.end, squareLow: d.squareLow, squareHigh: d.squareHigh };
        anchor.rect.x = rect.x;
        anchor.rect.y = rect.y;
        anchor.rect.width = rect.width;
        anchor.rect.height = rect.height;
        anchor.edges = side;
        anchor.gravity = side;
        anchor.updateAnchor();
    }

    anchor.window: host
    color: "transparent"
    readonly property real bodyHeight: Math.min(loader.implicitHeight + theme.space.l * 2, (host?.screen?.height ?? 1000) * 0.6)
    implicitWidth: sideways ? 380 + overlap : 380 + filletLow + filletHigh
    implicitHeight: sideways ? bodyHeight + filletLow + filletHigh : bodyHeight + overlap

    Item {
        id: content

        anchors.fill: parent

        DrawerFrame {
            id: frame

            anchors.fill: parent
            edge: root.host?.edge ?? "top"
            fillet: root.fillet
            filletLow: root.filletLow
            filletHigh: root.filletHigh
            overlap: root.overlap
            color: root.theme.color.surface
            lineWidth: root.host?.look?.border ?? 0

            Loader {
                id: loader

                x: root.theme.space.l
                y: root.theme.space.l
                width: parent.width - root.theme.space.l * 2
                source: root.slot ? Registry.url(root.slot.type) : ""

                onLoaded: {
                    item.block = Qt.binding(() => root.slot?.item ?? null);
                    item.screen = Qt.binding(() => root.slot?.screen ?? null);
                }
            }
        }

        HoverHandler {
            id: hover
        }
    }

    // Opening: slides out of the bar.
    NumberAnimation {
        id: appear
        target: frame
        property: "progress"
        from: 0
        to: 1
    }

    NumberAnimation {
        id: swap
        target: content
        property: "opacity"
        to: 1
        duration: 120
    }
}
