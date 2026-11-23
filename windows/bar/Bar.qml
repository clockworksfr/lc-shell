import QtQuick
import Quickshell
import Quickshell.Hyprland
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
//   length            0 = full width/height, else a centered bar (px)
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
    // Fixed length (centered on its edge) instead of full width/height.
    // `length`: px, or a share of the edge when under 1 (0.62: a centered
    // front panel, Facade / Modulaire).
    readonly property real edgeLength: vertical ? (screen?.height ?? 0) : (screen?.width ?? 0)
    readonly property int fixedLength: framed ? 0 : Math.max(0, Math.min((look.length ?? 0) > 0 && (look.length ?? 0) < 1 ? Math.round(edgeLength * look.length) : (look.length ?? 0), edgeLength - 2 * Math.max(gap, 8)))

    // Top-left of the bar window on its screen (popups and IPC need it).
    function origin(): point {
        const scr = screen;
        const x = edge === "right" ? scr.width - width - margins.right
            : edge === "left" || fixedLength === 0 ? margins.left
            : (scr.width - width) / 2;
        const y = edge === "bottom" ? scr.height - height - margins.bottom
            : edge === "top" || fixedLength === 0 ? margins.top
            : (scr.height - height) / 2;
        return Qt.point(x, y);
    }

    // Full length: anchored to its edge and both neighbours. Fixed length:
    // its edge only, the compositor centers it.
    anchors {
        top: edge === "top" || (fixedLength === 0 && edge !== "bottom")
        bottom: edge === "bottom" || (fixedLength === 0 && edge !== "top")
        left: edge === "left" || (fixedLength === 0 && edge !== "right")
        right: edge === "right" || (fixedLength === 0 && edge !== "left")
    }
    margins {
        top: edge === "bottom" ? 0 : gap
        bottom: edge === "top" ? 0 : gap
        left: edge === "right" ? 0 : gap
        right: edge === "left" ? 0 : gap
    }
    implicitHeight: vertical ? fixedLength : thickness
    implicitWidth: vertical ? thickness : fixedLength
    color: "transparent"
    WlrLayershell.namespace: "lc-bar"

    // "full": one band. Docked, the border is a single line on the inner edge.
    Rectangle {
        anchors.fill: parent
        visible: !bar.islands && !bar.framed
        radius: bar.look.floating ? bar.look.radius : 0
        color: Qt.alpha(bar.theme.color.surface, bar.look.opacity)
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

    // Right click on the bar (or a widget that doesn't use it): menu
    // (edit the bar, bar settings, settings).
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            if (!ShellState.editing)
                barMenu.openAt(mouse.x, mouse.y);
        }
    }

    // A widget's own menu (right click on it): its actions, Open (when it
    // has a panel), Edit this widget, Remove from the bar.
    function openWidgetMenu(slot: var, x: real, y: real): void {
        const item = slot.item;
        const own = (item?.contextActions ?? []).map(a => Object.assign({}, a, { id: `w:${a.id}` }));
        const list = [];
        if (item && typeof item.togglePanel === "function")
            list.push({ id: "open", icon: "open_in_new", text: I18n.tr("bar.menu.open") });
        list.push(...own);
        if (list.length)
            list.push({ isSeparator: true });
        list.push({ id: "edit", icon: "edit", text: I18n.tr("bar.menu.editWidget") });
        list.push({ id: "remove", icon: "delete", text: I18n.tr("bar.menu.removeWidget") });
        widgetMenu.slot = slot;
        widgetMenu.actions = list;
        widgetMenu.openAt(x, y);
    }

    MenuPopup {
        id: widgetMenu

        property var slot: null

        host: bar
        onPicked: id => {
            const slot = widgetMenu.slot;
            if (!slot)
                return;
            if (id === "open")
                slot.item?.togglePanel();
            else if (id === "edit") {
                ShellState.editing = true;
                BarEditor.selected = slot.at;
            } else if (id === "remove")
                BarEditor.remove(slot.at);
            else if (id.startsWith("w:"))
                slot.item?.contextAction(id.slice(2));
        }
    }

    BarMenu {
        id: barMenu
        host: bar
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

    // Open drawer (panel or card), so its island grows to carry it:
    // { slot (WidgetSlot), start, end, squareLow, squareHigh } along the
    // bar, in bar coordinates.
    property var drawerSpan: null

    // Where a drawer whose body is `bodyLen` long hangs for `slot`, along
    // the bar (bar coordinates; low = left / top end):
    // { start, end (with the fillets), low, high (fillet sizes),
    //   squareLow, squareHigh }.
    // Centered on the widget, body kept 8 px from the screen's edges. In
    // islands, when the island can't grow far enough on a side (screen or
    // bar end), the body aligns with the island's end there, without a
    // fillet, and that corner of the island turns square (design study,
    // case B).
    function drawerPlace(slot: Item, bodyLen: real, fillet: real): var {
        const p = slot.mapToItem(contentItem, 0, 0);
        const center = vertical ? p.y + slot.height / 2 : p.x + slot.width / 2;
        const o = origin();
        const off = vertical ? o.y : o.x;
        const scrLen = vertical ? screen.height : screen.width;
        const len = vertical ? height : width;
        let b0 = Math.max(8 - off, Math.min(center - bodyLen / 2, scrLen - off - bodyLen - 8));
        let low = fillet;
        let high = fillet;
        let squareLow = false;
        let squareHigh = false;
        const group = slot.parent?.parent ?? null;
        if (islands && group) {
            const gp = group.mapToItem(contentItem, 0, 0);
            const i0 = vertical ? gp.y : gp.x;
            const i1 = i0 + (vertical ? group.height : group.width);
            const r = look.radius ?? 0;
            const lo = Math.min(i0, 8);
            const hi = Math.max(i1, len - 8);
            if (Math.min(i0, b0 - fillet - r) < lo) {
                b0 = i0;
                low = 0;
                squareLow = true;
            }
            if (Math.max(i1, b0 + bodyLen + fillet + r) > hi && !squareLow) {
                b0 = i1 - bodyLen;
                high = 0;
                squareHigh = true;
            }
        } else {
            // Full bar: fillets never leave the bar.
            low = Math.min(fillet, Math.max(0, b0));
            high = Math.min(fillet, Math.max(0, len - b0 - bodyLen));
        }
        return { start: b0 - low, end: b0 + bodyLen + high, low: low, high: high, squareLow: squareLow, squareHigh: squareHigh };
    }

    // --- Hover cards (docs/bar-editing.md) ---
    // 350 ms still on a block shows its card; moving to a neighbour while
    // a card is open (or just closed) switches at once; leaving keeps it
    // 250 ms (time to reach the card); the pointer on the card keeps it.

    property Item hoveredSlot: null
    property real cardClosedAt: 0

    function widgetHovered(slot: Item, inside: bool): void {
        // A pinned card stays on its widget.
        if (card.pinned) {
            hoveredSlot = inside ? slot : (hoveredSlot === slot ? null : hoveredSlot);
            return;
        }
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
            if (card.pinned || card.hovered || bar.hoveredSlot)
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

        function onMenuRequested(menu: string, screenName: string): void {
            const target = screenName || Hyprland.focusedMonitor?.name || "";
            if (target !== bar.screen.name || menu !== "bar")
                return;
            const slot = ShellState.slots.find(s => s.host === bar && s.type === "clock" && s.visible) ?? null;
            const p = slot ? slot.mapToItem(bar.contentItem, slot.width / 2, slot.height / 2) : Qt.point(bar.width / 2, bar.height / 2);
            barMenu.openAt(p.x, bar.vertical ? p.y : (bar.edge === "top" ? bar.height : 0));
        }

        // A widget's click: pin its card, or close it if it's pinned there.
        function onCardPinRequested(widget: var): void {
            const slot = ShellState.slots.find(s => s.host === bar && s.item === widget);
            if (!slot || !Registry.has(slot.type))
                return;
            if (card.pinned && card.shown === slot)
                card.hide();
            else
                card.pin(slot);
        }

        function onBarSnapshotRequested(screenName: string, path: string): void {
            if (screenName !== bar.screen.name)
                return;
            bar.contentItem.grabToImage(r => r.saveToFile(`${path}-bar.png`));
            if (card.phase === "open")
                card.snapshot(`${path}-card.png`);
        }

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
        const slots = ShellState.slots.filter(s => s.host === bar && s.zoneName === zone.name && s.visible).sort((a, b) => a.groupIndex - b.groupIndex || a.widgetIndex - b.widgetIndex);
        const half = look.spacing / 2;
        for (const s of slots) {
            const p = s.mapToItem(bar.contentItem, 0, 0);
            const start = axis(p);
            const size = vertical ? s.height : s.width;
            if (pos < start + size / 2) {
                dropTarget = { zone: zone.name, group: s.groupIndex, index: s.widgetIndex };
                marker.place(start - half);
                return;
            }
        }
        const last = slots[slots.length - 1];
        if (last) {
            const p = last.mapToItem(bar.contentItem, 0, 0);
            dropTarget = { zone: zone.name, group: last.groupIndex, index: last.widgetIndex + 1 };
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
            text: BarEditor.dragging ? I18n.tr(`widget.${BarEditor.dragging.type}`) : ""
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
