import QtQuick
import Quickshell
import qs.services
import qs.theme

// The border of a shell window (settings, detail panels), like Hyprland's
// window borders: their width (general:border_size) and the theme's window
// color (`color.windowBorder`, else the accent; white in Matrix). Laid over
// the window's content, following its corners.
Rectangle {
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    anchors.fill: parent
    color: "transparent"
    border.width: HyprBorders.borderSize
    border.color: HyprBorders.enabled ? (theme.color.windowBorder ?? theme.color.accent) : theme.color.line
}
