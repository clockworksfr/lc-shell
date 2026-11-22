import QtQuick
import Quickshell
import qs.theme

// Base text: every label in the shell goes through this.
// `theme` is the theme of the screen the text is shown on.
Text {
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    // Small label: follows the theme's label case (e.g. upper in Matrix).
    property bool label: false

    color: theme.color.fg
    font.family: label ? theme.font.mono : theme.font.family
    font.pixelSize: label ? theme.font.sizeS : theme.font.sizeM
    font.capitalization: label && theme.style.labelCase === "upper" ? Font.AllUppercase : Font.MixedCase
    verticalAlignment: Text.AlignVCenter
}
