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

    text: vertical ? compactText : fullText
    font.pixelSize: vertical ? theme.font.sizeS : theme.font.sizeM
    horizontalAlignment: Text.AlignHCenter
    width: vertical && crossSize > 0 ? crossSize : implicitWidth
    elide: Text.ElideRight
}
