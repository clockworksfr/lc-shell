import QtQuick
import Quickshell
import qs.components
import qs.theme

// Shown in place of a block name that isn't in the registry,
// so a typo in layout.json is visible instead of silently ignored.
ThemedText {
    property ShellScreen screen
    property var options: ({})
    property string type

    text: `?${type}`
    color: Theme.color.urgent
}
