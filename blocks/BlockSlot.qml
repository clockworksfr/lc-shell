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

    readonly property string type: Registry.typeOf(entry)
    readonly property var item: loader.item
    readonly property bool hovered: hover.hovered

    visible: item?.shown ?? true
    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    onHoveredChanged: host?.blockHovered(root, hovered)

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

    Connections {
        target: ShellState

        function onPanelRequested(type: string, screenName: string): void {
            const target = screenName || Hyprland.focusedMonitor?.name || "";
            if (type === root.type && root.screen?.name === target && typeof root.item?.togglePanel === "function")
                root.item.togglePanel();
        }
    }
}
