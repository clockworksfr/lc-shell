import QtQuick
import Quickshell
import qs.components
import qs.theme

// Titled group of fields on a settings page.
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    property string title

    width: parent?.width ?? 0
    spacing: theme.space.s

    ThemedText {
        text: root.title
        label: true
        color: root.theme.color.soft
        topPadding: root.theme.space.m
    }
}
