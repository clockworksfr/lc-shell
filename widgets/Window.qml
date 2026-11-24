import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.components
import qs.i18n
import qs.services

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
    // Reads the entry list so it re-runs once desktop entries are loaded.
    readonly property var entry: (DesktopEntries.applications.values.length, appClass) ? DesktopEntries.heuristicLookup(appClass) : null
    readonly property string appName: entry?.name || appClass
    // Compact: the app's first word ("Brave Web Browser" -> "Brave").
    readonly property string shortName: (appName.split(" ")[0] || appName)
    // Titles often end with the app's name ("… – Brave"): don't repeat it.
    readonly property string cleanTitle: title.replace(new RegExp(`\\s*[-–—|]\\s*${shortName.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}[^-–—|]*$`, "i"), "")
    readonly property string title: current?.title ?? ""

    readonly property bool shown: valid
    readonly property int maxWidth: options.maxWidth ?? (size === "extended" ? 720 : 420)

    // Modulaire: the title in a green LCD, "APP ▸ TITLE" (design "Barre").
    readonly property bool lcd: theme?.style.module === "modulaire" && !vertical
    implicitWidth: vertical ? Math.max(crossSize, 24) : Math.min(row.implicitWidth + (lcd ? 20 : 0), maxWidth)
    implicitHeight: vertical ? 24 : row.implicitHeight + (lcd ? 6 : 0)

    Rectangle {
        visible: root.lcd && root.valid
        anchors.fill: parent
        radius: 4
        color: "#1A2410"
        border.width: 2
        border.color: "#80000000"
    }

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        // A position, not a conditional anchor (a removed anchor leaves the
        // row where it was when the bar changes edge).
        x: root.vertical ? (parent.width - width) / 2 : root.lcd ? 10 : 0
        spacing: 8

        AppIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: 18
            name: root.entry?.icon ?? ""
            visible: !!root.entry?.icon && !root.lcd
            source: root.entry?.icon ? Quickshell.iconPath(root.entry.icon, true) : ""
        }

        // No icon: the app's initial in a small badge.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.entry?.icon && !!root.appName && !root.lcd
            width: 18
            height: 18
            radius: 5
            color: root.theme?.color.surface3 ?? "grey"

            ThemedText {
                anchors.centerIn: parent
                text: root.appName.charAt(0).toUpperCase()
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        ThemedText {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.vertical
            width: Math.min(implicitWidth, root.maxWidth - (root.lcd ? 20 : 26))
            elide: Text.ElideRight
            font.family: root.lcd ? (root.theme.font.lcd ?? root.theme.font.mono) : (root.theme?.font.family ?? "sans-serif")
            font.capitalization: root.lcd ? Font.AllUppercase : Font.MixedCase
            font.pixelSize: root.lcd ? 15 : root.theme?.font.sizeM ?? 14
            // Titles can be private (mail subjects, chats): app name only
            // while the screen is shared.
            text: Screens.sharing ? root.shortName
                : root.size === "compact" ? root.shortName
                : root.size === "extended" ? [root.shortName, root.cleanTitle].filter(s => !!s).join(" — ")
                : root.lcd ? [root.shortName, root.cleanTitle].filter(s => !!s).join(" ▸ ")
                : root.title || root.appName
            color: root.lcd ? "#C6F37A" : root.theme?.color.soft ?? color
        }
    }
}
