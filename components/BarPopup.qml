import QtQuick
import Quickshell
import qs.theme

// Popup attached to a bar block, opened below it (above it on a bottom
// bar, the compositor flips it). Clicking outside closes it.
// Children go into a Column.
PopupWindow {
    id: root

    required property Item anchorItem
    default property alias content: column.data

    anchor.item: anchorItem
    // From the block down to just below the bar.
    anchor.rect.width: anchorItem.width
    anchor.rect.height: anchorItem.height + (Theme.bar.height - anchorItem.height) / 2 + Theme.space.xs
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    grabFocus: true
    color: "transparent"
    implicitWidth: column.implicitWidth + Theme.space.m * 2
    implicitHeight: column.implicitHeight + Theme.space.m * 2

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius.m
        color: Theme.color.surface

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: Theme.space.m
            spacing: Theme.space.s
        }
    }
}
