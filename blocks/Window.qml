import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.i18n

// Active window of this screen: app icon and window title.
// Sizes: compact = app name, normal = title, extended = app — title.
// Vertical bar: icon only. Hidden when the screen has no window focused yet.
// Options: maxWidth (px).
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    property bool vertical: false
    property int crossSize: 0

    readonly property var theme: QsWindow.window?.theme ?? null
    readonly property string size: options.size ?? "normal"

    // The focused window if it's on this screen, else the last one that was;
    // until a focus change is seen (Hyprland doesn't report the focused
    // window at startup), a window of the screen's active workspace.
    property var lastFocused: null
    readonly property var active: Hyprland.activeToplevel
    onActiveChanged: if (onThisScreen(active)) lastFocused = active
    readonly property var current: onThisScreen(lastFocused) ? lastFocused : Hyprland.toplevels.values.find(t => onThisScreen(t)) ?? null

    // A toplevel's monitor isn't always known: go through its workspace.
    function onThisScreen(toplevel: var): bool {
        return !!toplevel && toplevel.workspace?.monitor?.name === screen?.name && (toplevel.workspace?.active ?? false);
    }

    readonly property bool valid: !!current
    readonly property string appClass: current?.lastIpcObject?.class ?? current?.wayland?.appId ?? ""
    readonly property var entry: appClass ? DesktopEntries.heuristicLookup(appClass) : null
    readonly property string appName: entry?.name || appClass
    readonly property string title: current?.title ?? ""

    readonly property bool shown: valid
    readonly property int maxWidth: options.maxWidth ?? (size === "extended" ? 720 : 420)

    implicitWidth: vertical ? Math.max(crossSize, 24) : Math.min(row.implicitWidth, maxWidth)
    implicitHeight: vertical ? 24 : row.implicitHeight

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
        spacing: 8

        IconImage {
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            visible: !!root.entry?.icon
            source: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
            asynchronous: true
        }

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.vertical
            width: Math.min(implicitWidth, root.maxWidth - 26)
            elide: Text.ElideRight
            text: root.size === "compact" ? root.appName
                : root.size === "extended" ? [root.appName, root.title].filter(s => !!s).join(" — ")
                : root.title || root.appName
            color: root.theme?.color.soft ?? color
        }
    }
}
