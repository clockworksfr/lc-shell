import QtQuick
import Quickshell
import qs.cards
import qs.components
import qs.services
import qs.theme

// The bar's hover card: one per bar, moved from block to block. Opens
// toward the inside of the screen, centered on the block, doesn't take the
// keyboard. Content comes from cards/<Type>Card.qml.
PopupWindow {
    id: root

    required property var host
    // WidgetSlot the card is shown for.
    property Item slot: null
    readonly property bool hovered: hover.hovered

    readonly property var theme: host?.theme ?? Themes.fallback
    readonly property int gap: theme.space.s

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
            content.opacity = switching ? 0.4 : 0;
            content.scale = switching ? 1 : 0.96;
            root.visible = true;
            if (switching)
                swap.restart();
            else
                appear.restart();
        });
    }

    function hide(): void {
        visible = false;
        slot = null;
    }

    onVisibleChanged: ShellState.card = { visible: visible, type: slot?.type ?? "", screen: host?.screen?.name ?? "" }

    function place(): void {
        if (!slot || !host)
            return;
        const p = slot.mapToItem(host.contentItem, 0, 0);
        const w = slot.width;
        const h = slot.height;
        let rect;
        let side;
        switch (host.edge) {
        case "bottom":
            rect = Qt.rect(p.x, -gap, w, 0);
            side = Edges.Top;
            break;
        case "left":
            rect = Qt.rect(host.width + gap, p.y, 0, h);
            side = Edges.Right;
            break;
        case "right":
            rect = Qt.rect(-gap, p.y, 0, h);
            side = Edges.Left;
            break;
        default:
            rect = Qt.rect(p.x, host.height + gap, w, 0);
            side = Edges.Bottom;
        }
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
    implicitWidth: 380
    implicitHeight: Math.min(frame.implicitHeight, (host?.screen?.height ?? 1000) * 0.6)

    Item {
        id: content

        anchors.fill: parent
        transformOrigin: root.host?.edge === "bottom" ? Item.Bottom : Item.Top

        Rectangle {
            id: frame

            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: loader.implicitHeight + root.theme.space.l * 2
            height: parent.height
            radius: root.theme.radius.panel
            color: root.theme.color.surface
            border.width: root.theme.border.width
            border.color: root.theme.color.line
            clip: true

            Glass {}

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

    ParallelAnimation {
        id: appear
        NumberAnimation {
            target: content
            property: "opacity"
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: content
            property: "scale"
            to: 1
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation {
        id: swap
        target: content
        property: "opacity"
        to: 1
        duration: 120
    }
}
