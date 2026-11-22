import QtQuick
import Quickshell
import qs.theme

// An icon from the bundled set (tools/icons.txt), by name.
Text {
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string name
    property bool filled: false
    property real size: theme.font.sizeL + 2

    text: Icons.glyph(name)
    color: theme.color.ink
    font.family: filled ? "lc Symbols Filled" : "lc Symbols"
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
