import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.cards
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Bar of "normal" screens, on any edge. Its look comes from the theme
// (theme.bar) and can be overridden per mode/screen in settings, next to
// the block lists:
//   position          "top" | "bottom" | "left" | "right"
//   left/center/right block entries; on a vertical bar: top/middle/bottom
//                     (also accepted as start/center/end)
//   style             "full" | "islands"
//   floating, margin, radius, opacity, border, padding, spacing,
//   height (horizontal thickness), verticalWidth (vertical thickness)
PanelWindow {
    id: bar

    property var config: ({})
    property var theme: Themes.fallback
    // Part of a frame (FrameWindow draws the background): docked, no
    // islands, no own background.
    property bool framed: false

    readonly property var look: Object.assign({}, theme.bar, config)
    // "top" | "bottom" | "left" | "right"; read by popups to open inward.
    readonly property string edge: ["top", "bottom", "left", "right"].includes(look.position) ? look.position : "top"
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool islands: look.style === "islands" && !framed
    readonly property int thickness: vertical ? look.verticalWidth : look.height
    readonly property int gap: look.floating && !framed ? look.margin : 0
    // Space taken from the screen edge (what popups must clear).
    readonly property int extent: thickness + gap

    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: edge !== "right"
        right: edge !== "left"
    }
    margins {
        top: edge === "bottom" ? 0 : gap
        bottom: edge === "top" ? 0 : gap
        left: edge === "right" ? 0 : gap
        right: edge === "left" ? 0 : gap
    }
    implicitHeight: vertical ? 0 : thickness
    implicitWidth: vertical ? thickness : 0
    color: "transparent"
    WlrLayershell.namespace: "lc-bar"

    // "full": one band. Docked, the border is a single line on the inner edge.
    Rectangle {
        anchors.fill: parent
        visible: !bar.islands && !bar.framed
        radius: bar.look.floating ? bar.look.radius : 0
        color: Qt.alpha(bar.theme.color.bg, bar.look.opacity)
        border.width: bar.look.floating ? bar.look.border : 0
        border.color: bar.theme.color.line

        Glass {}

        Rectangle {
            visible: !bar.look.floating && bar.look.border > 0
            color: bar.theme.color.line
            x: bar.edge === "left" ? parent.width - width : 0
            y: bar.edge === "top" ? parent.height - height : 0
            width: bar.vertical ? bar.look.border : parent.width
            height: bar.vertical ? parent.height : bar.look.border
        }
    }

    // Right click on the bar (outside blocks): edit mode.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: ShellState.editing = true
    }

    // Start / center / end zones, along the bar.
    BarZone {
        id: startZone
        host: bar
        name: "left"
        entries: bar.look.start ?? bar.look.top ?? bar.look.left ?? []
        x: bar.vertical ? 0 : (bar.islands ? 0 : bar.look.padding)
        y: bar.vertical ? (bar.islands ? 0 : bar.look.padding) : 0
    }

    BarZone {
        id: centerZone
        host: bar
        name: "center"
        entries: bar.look.center ?? bar.look.middle ?? []
        x: bar.vertical ? 0 : (bar.width - width) / 2
        y: bar.vertical ? (bar.height - height) / 2 : 0
    }

    BarZone {
        id: endZone
        host: bar
        name: "right"
        entries: bar.look.end ?? (bar.vertical ? bar.look.bottom : undefined) ?? bar.look.right ?? []
        x: bar.vertical ? 0 : bar.width - width - (bar.islands ? 0 : bar.look.padding)
        y: bar.vertical ? bar.height - height - (bar.islands ? 0 : bar.look.padding) : 0
    }

    // --- Hover cards (docs/bar-editing.md) ---
    // 350 ms still on a block shows its card; moving to a neighbour while
    // a card is open (or just closed) switches at once; leaving keeps it
    // 250 ms (time to reach the card); the pointer on the card keeps it.

    property Item hoveredSlot: null
    property real cardClosedAt: 0

    function blockHovered(slot: Item, inside: bool): void {
        if (inside) {
            hoveredSlot = slot;
            hideCard.stop();
            if (card.visible || Date.now() - cardClosedAt < 600)
                showCardFor(slot);
            else
                showCard.restart();
        } else if (hoveredSlot === slot) {
            hoveredSlot = null;
            showCard.stop();
            hideCard.restart();
        }
    }

    function showCardFor(slot: Item): void {
        if (!slot || !Registry.has(slot.type) || slot.item?.panelOpen)
            return;
        card.showFor(slot);
    }

    Timer {
        id: showCard
        interval: 350
        onTriggered: bar.showCardFor(bar.hoveredSlot)
    }

    Timer {
        id: hideCard
        interval: 250
        onTriggered: {
            if (card.hovered || bar.hoveredSlot)
                return;
            card.hide();
            bar.cardClosedAt = Date.now();
        }
    }

    // A click opening the block's panel closes its card.
    readonly property bool cardSuppressed: card.slot?.item?.panelOpen ?? false
    onCardSuppressedChanged: if (cardSuppressed) card.hide()

    Connections {
        target: ShellState

        function onCardRequested(type: string, screenName: string): void {
            if (screenName && screenName !== bar.screen.name)
                return;
            if (!type) {
                card.hide();
                return;
            }
            const slot = ShellState.slots.find(s => s.host === bar && s.type === type && s.visible);
            if (slot)
                bar.showCardFor(slot);
        }
    }

    HoverCard {
        id: card
        host: bar
        onHoveredChanged: if (!hovered && !bar.hoveredSlot) hideCard.restart()
    }

    // --- Edit mode: drag and drop (BarEditor) ---

    // { zone, group, index } where a dragged block would land; group -1 =
    // new group at the zone's end.
    property var dropTarget: null
    property point dragPoint

    function within(item: Item, x: real, y: real, pad: real): bool {
        const p = item.mapToItem(bar.contentItem, 0, 0);
        return item.visible && x >= p.x - pad && x <= p.x + item.width + pad && y >= p.y - pad && y <= p.y + item.height + pad;
    }

    function dragMove(x: real, y: real): void {
        dragPoint = Qt.point(x, y);
        const zones = [startZone, centerZone, endZone];
        const axis = p => vertical ? p.y : p.x;
        const pos = vertical ? y : x;
        // The zone under the pointer, else the nearest one along the bar.
        let zone = zones.find(z => within(z, x, y, 12));
        if (!zone) {
            const distance = z => {
                const p = z.mapToItem(bar.contentItem, 0, 0);
                const start = axis(p);
                const end = start + (vertical ? z.height : z.width);
                return pos < start ? start - pos : pos > end ? pos - end : 0;
            };
            zone = zones.filter(z => z.visible).sort((a, b) => distance(a) - distance(b))[0];
        }
        if (!zone) {
            dropTarget = null;
            return;
        }
        if (within(zone.plus, x, y, 6)) {
            dropTarget = { zone: zone.name, group: -1, index: 0 };
            const p = zone.plus.mapToItem(bar.contentItem, 0, 0);
            marker.place(axis(p) - 4);
            return;
        }
        const slots = ShellState.slots.filter(s => s.host === bar && s.zoneName === zone.name && s.visible).sort((a, b) => a.groupIndex - b.groupIndex || a.blockIndex - b.blockIndex);
        const half = look.spacing / 2;
        for (const s of slots) {
            const p = s.mapToItem(bar.contentItem, 0, 0);
            const start = axis(p);
            const size = vertical ? s.height : s.width;
            if (pos < start + size / 2) {
                dropTarget = { zone: zone.name, group: s.groupIndex, index: s.blockIndex };
                marker.place(start - half);
                return;
            }
        }
        const last = slots[slots.length - 1];
        if (last) {
            const p = last.mapToItem(bar.contentItem, 0, 0);
            dropTarget = { zone: zone.name, group: last.groupIndex, index: last.blockIndex + 1 };
            marker.place(axis(p) + (vertical ? last.height : last.width) + half);
        } else {
            dropTarget = { zone: zone.name, group: 0, index: 0 };
            const p = zone.mapToItem(bar.contentItem, 0, 0);
            marker.place(axis(p) + (vertical ? zone.height : zone.width) / 2);
        }
    }

    function dragDrop(): void {
        const from = BarEditor.dragging?.at;
        const to = dropTarget;
        BarEditor.dragging = null;
        dropTarget = null;
        if (from && to)
            BarEditor.move(from, { screen: from.screen, zone: to.zone, group: to.group, index: to.index });
    }

    // Insertion cursor.
    Rectangle {
        id: marker

        function place(position: real): void {
            if (bar.vertical) {
                x = 4;
                y = position - 1.5;
            } else {
                x = position - 1.5;
                y = 4;
            }
        }

        visible: !!bar.dropTarget && bar.dropTarget.group !== -1
        width: bar.vertical ? bar.width - 8 : 3
        height: bar.vertical ? 3 : bar.height - 8
        radius: 1.5
        color: bar.theme.color.accent
        z: 10
    }

    // The block being dragged, following the pointer.
    Rectangle {
        visible: !!BarEditor.dragging && BarEditor.dragging.at.screen === bar.screen.name
        x: bar.dragPoint.x - width / 2
        y: bar.dragPoint.y - height / 2
        width: ghostText.implicitWidth + 20
        height: 26
        radius: 13
        rotation: -1.5
        scale: 1.05
        color: bar.theme.color.surface
        border.width: 1
        border.color: bar.theme.color.accent
        opacity: 0.92
        z: 11

        ThemedText {
            id: ghostText
            anchors.centerIn: parent
            text: BarEditor.dragging ? I18n.tr(`block.${BarEditor.dragging.type}`) : ""
            font.pixelSize: bar.theme.font.sizeS
        }
    }

    // No hover cards while editing.
    Connections {
        target: ShellState
        function onEditingChanged(): void {
            if (ShellState.editing)
                card.hide();
        }
    }
}
