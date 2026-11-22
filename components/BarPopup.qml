import QtQuick
import Quickshell
import qs.theme

// Popup attached to a bar block. It opens toward the inside of the screen,
// just past the bar's inner edge, whatever the bar's edge (top, bottom,
// left, right), centered on the block. Clicking outside closes it.
// Open/close with toggle(); children go into a Column.
PopupWindow {
    id: root

    required property Item anchorItem
    default property alias content: column.data

    readonly property var bar: anchorItem?.QsWindow.window ?? null
    // Same theme as the bar it opens from.
    readonly property var theme: bar?.theme ?? Themes.fallback
    readonly property string edge: bar?.edge ?? "top"
    readonly property int gap: theme.space.s

    function toggle(): void {
        if (visible) {
            visible = false;
            return;
        }
        place();
        visible = true;
    }

    // A zero-thickness line along the bar's inner edge, in block coordinates.
    function place(): void {
        if (!bar)
            return;
        const p = anchorItem.mapToItem(bar.contentItem, 0, 0);
        const w = anchorItem.width;
        const h = anchorItem.height;
        let rect;
        let side;
        switch (edge) {
        case "bottom":
            rect = Qt.rect(0, -p.y - gap, w, 0);
            side = Edges.Top;
            break;
        case "left":
            rect = Qt.rect(bar.width - p.x + gap, 0, 0, h);
            side = Edges.Right;
            break;
        case "right":
            rect = Qt.rect(-p.x - gap, 0, 0, h);
            side = Edges.Left;
            break;
        default:
            rect = Qt.rect(0, bar.height - p.y + gap, w, 0);
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

    anchor.item: anchorItem

    grabFocus: true
    color: "transparent"
    implicitWidth: column.implicitWidth + theme.space.m * 2
    implicitHeight: column.implicitHeight + theme.space.m * 2

    Rectangle {
        anchors.fill: parent
        radius: root.theme.radius.panel
        color: root.theme.color.surface
        border.width: root.theme.border.width
        border.color: root.theme.color.line

        Glass {}

        Column {
            id: column

            anchors.fill: parent
            anchors.margins: root.theme.space.m
            spacing: root.theme.space.s
        }
    }
}
