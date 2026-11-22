import QtQuick
import Quickshell
import qs.theme

// Popup attached to a bar block, opened below it (above it on a bottom
// bar, the compositor flips it). Clicking outside closes it.
// Children go into a Column.
PopupWindow {
    id: root

    // Same theme as the bar it opens from.
    readonly property var theme: anchorItem?.QsWindow.window?.theme ?? Themes.fallback

    required property Item anchorItem
    default property alias content: column.data

    anchor.item: anchorItem
    // From the block down to just below the bar.
    anchor.rect.width: anchorItem.width
    anchor.rect.height: anchorItem.height + (root.theme.bar.height - anchorItem.height) / 2 + root.theme.space.xs
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    grabFocus: true
    color: "transparent"
    implicitWidth: column.implicitWidth + root.theme.space.m * 2
    implicitHeight: column.implicitHeight + root.theme.space.m * 2

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radius.panel
        color: root.theme.color.surface

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: root.theme.space.m
            spacing: root.theme.space.s
        }
    }
}
