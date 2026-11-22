import QtQuick
import Quickshell

// Instantiates one block from a layout entry and hands it its context.
// Blocks expose `screen`, `options`, and optionally:
//   `vertical`  (bool) set when the bar is vertical: show a compact form
//   `crossSize` (int)  room across the bar (bar thickness minus padding)
//   `type`      for the Unknown placeholder
// A block can hide itself (and its spacing) with `readonly property bool shown`.
Loader {
    id: root

    required property var entry
    property ShellScreen screen
    property bool vertical: false
    property int crossSize: 0

    readonly property string type: Registry.typeOf(entry)

    source: Registry.url(type)
    visible: item?.shown ?? true

    onLoaded: {
        item.screen = Qt.binding(() => root.screen);
        item.options = Qt.binding(() => Registry.optionsOf(root.entry));
        for (const name of ["vertical", "crossSize", "type"]) {
            if (name in item)
                item[name] = Qt.binding(() => root[name]);
        }
    }
}
