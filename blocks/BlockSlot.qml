import QtQuick
import Quickshell

// Instantiates one block from a layout entry and hands it its context.
// Blocks expose `screen`, `options` and (for unknown ones) `type`.
// A block can hide itself (and its spacing) with `readonly property bool shown`.
Loader {
    id: root

    required property var entry
    property ShellScreen screen

    readonly property string type: Registry.typeOf(entry)

    source: Registry.url(type)
    visible: item?.shown ?? true

    onLoaded: {
        item.screen = Qt.binding(() => root.screen);
        item.options = Qt.binding(() => Registry.optionsOf(root.entry));
        if ("type" in item)
            item.type = Qt.binding(() => root.type);
    }
}
