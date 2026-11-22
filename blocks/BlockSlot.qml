import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Instantiates one block from a layout entry and hands it its context.
// Blocks expose `screen`, `options`, and optionally:
//   `vertical`  (bool) set when the bar is vertical: show a compact form
//   `crossSize` (int)  room across the bar (bar thickness minus padding)
//   `type`      for the Unknown placeholder
//   `togglePanel()`, `panelOpen` for blocks with a click panel
// A block can hide itself (and its spacing) with `readonly property bool shown`.
//
// Hovering a block tells the bar (`host.blockHovered`), which shows the
// block's hover card (cards/). Passive: the block still gets its clicks.
Item {
    id: root

    required property var entry
    property ShellScreen screen
    property bool vertical: false
    property int crossSize: 0
    // The Bar window (for hover cards); null outside a bar.
    property var host: null
    // Position in the bar's layout (edit mode).
    property string zoneName
    property int groupIndex: 0
    property int blockIndex: 0

    readonly property var at: ({ screen: screen?.name ?? "", zone: zoneName, group: groupIndex, index: blockIndex })
    readonly property bool editing: ShellState.editing && !!host
    readonly property bool selected: editing && JSON.stringify(BarEditor.selected) === JSON.stringify(at)
    readonly property bool lifted: editing && JSON.stringify(BarEditor.dragging?.at) === JSON.stringify(at)

    readonly property string type: Registry.typeOf(entry)
    readonly property var item: loader.item
    readonly property bool hovered: hover.hovered

    // Blocks that hide themselves still show (dimmed) while editing.
    visible: (item?.shown ?? true) || editing
    opacity: lifted ? 0.35 : (item?.shown ?? true) ? 1 : 0.4
    implicitWidth: Math.max(loader.implicitWidth, editing ? 16 : 0)
    implicitHeight: Math.max(loader.implicitHeight, editing ? 16 : 0)

    onHoveredChanged: if (!editing) host?.blockHovered(root, hovered)

    Component.onCompleted: if (host) ShellState.addSlot(root)
    Component.onDestruction: ShellState.removeSlot(root)

    Loader {
        id: loader

        source: Registry.url(root.type)

        onLoaded: {
            item.screen = Qt.binding(() => root.screen);
            item.options = Qt.binding(() => Registry.optionsOf(root.entry));
            for (const name of ["vertical", "crossSize", "type"]) {
                if (name in item)
                    item[name] = Qt.binding(() => root[name]);
            }
        }
    }

    HoverHandler {
        id: hover
    }

    // Edit mode: outline, click to select, drag to move.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        visible: root.editing
        radius: 6
        color: root.selected ? Qt.alpha(root.host?.theme.color.accent ?? "white", 0.2) : "transparent"
        border.width: root.selected ? 2 : 1
        border.color: Qt.alpha(root.host?.theme.color.accent ?? "white", root.selected ? 1 : 0.5)
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        enabled: root.editing
        cursorShape: drag.active || root.lifted ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property point origin
        property bool moved: false

        onPressed: mouse => {
            origin = Qt.point(mouse.x, mouse.y);
            moved = false;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            if (!moved && Math.hypot(mouse.x - origin.x, mouse.y - origin.y) < 4)
                return;
            if (!moved) {
                moved = true;
                BarEditor.dragging = { at: root.at, type: root.type };
            }
            const p = mapToItem(root.host.contentItem, mouse.x, mouse.y);
            root.host.dragMove(p.x, p.y);
        }
        onReleased: {
            if (moved)
                root.host.dragDrop();
            else
                BarEditor.selected = root.selected ? null : root.at;
            moved = false;
        }
    }

    Connections {
        target: ShellState

        function onPanelRequested(type: string, screenName: string): void {
            const target = screenName || Hyprland.focusedMonitor?.name || "";
            if (type === root.type && root.screen?.name === target && typeof root.item?.togglePanel === "function")
                root.item.togglePanel();
        }
    }
}
