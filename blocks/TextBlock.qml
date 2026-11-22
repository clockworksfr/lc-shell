import QtQuick
import Quickshell
import qs.components

// Base of text blocks. `fullText` on a horizontal bar, `compactText` on a
// vertical one (short, usually two lines: label then value), centered and
// clipped to the bar's width. Never rotated. Blocks pick their text by
// `size` too (compact: the value alone, extended: with context).
ThemedText {
    property ShellScreen screen
    property var options: ({})
    property bool vertical: false
    property int crossSize: 0

    // "compact" | "normal" | "extended" (edit mode, options.size).
    readonly property string size: options.size ?? "normal"

    property string fullText
    property string compactText: fullText

    // Icon mode (theme.style.statusIcons): `icon` + `iconText` (usually the
    // value alone; empty = icon only). Vertical: icon over the value.
    property string icon
    property string iconText
    property bool iconFilled: false
    readonly property bool useIcon: !!icon && theme.style.statusIcons !== false

    text: useIcon ? iconText : vertical ? compactText : fullText
    leftPadding: useIcon && !vertical ? iconItem.width + (iconText ? 6 : 0) : 0
    topPadding: useIcon && vertical ? iconItem.height + (iconText ? 2 : 0) : 0
    font.pixelSize: vertical ? theme.font.sizeS : theme.font.sizeM
    horizontalAlignment: Text.AlignHCenter
    width: vertical && crossSize > 0 ? crossSize : implicitWidth
    elide: Text.ElideRight

    Icon {
        id: iconItem

        visible: parent.useIcon
        name: parent.icon
        filled: parent.iconFilled
        color: parent.color
        size: parent.vertical ? 20 : parent.theme.font.sizeL + 3
        x: parent.vertical ? (parent.width - width) / 2 : 0
        y: parent.vertical ? 0 : (parent.height - height) / 2
    }
}
