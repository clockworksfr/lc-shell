import QtQuick
import Quickshell

// The dynamic island's card: the player's card while something plays,
// else the clock's.
Loader {
    id: root

    property var block
    property ShellScreen screen

    width: parent?.width ?? 0
    source: block?.activity === "media" ? "MediaCard.qml" : "ClockCard.qml"
    onLoaded: {
        item.block = Qt.binding(() => root.block);
        item.screen = Qt.binding(() => root.screen);
        if ("width" in item)
            item.width = Qt.binding(() => root.width);
    }
}
