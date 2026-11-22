import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.i18n
import qs.theme

// Settings app: a regular window (tiled or floated by Hyprland like any
// other), sidebar of pages on the left. Every change is applied live and
// written to the user settings.
FloatingWindow {
    id: win

    // Normal-screen theme: the window lives among the user's windows.
    property var theme: Themes.resolve(Themes.themeFor("normal"), false, "normal")

    // The "lc-shell · " prefix lets Hyprland rules (and the float below) find it.
    title: `lc-shell · ${I18n.tr("settings.title")}`
    implicitWidth: 980
    implicitHeight: 720
    color: theme.color.bg

    onVisibleChanged: {
        if (!visible)
            Settings.opened = false;
        else
            floatIt.restart();
    }

    // Float it, sized and centered, rather than tiling it over the user's
    // windows (Hyprland tiles new windows by default).
    Timer {
        id: floatIt
        interval: 150
        onTriggered: {
            const target = `window = "title:^lc-shell · "`;
            Hyprland.dispatch(`hl.dsp.window.float({ action = "set", ${target} })`);
            Hyprland.dispatch(`hl.dsp.window.resize({ x = ${win.implicitWidth}, y = ${win.implicitHeight}, ${target} })`);
            Hyprland.dispatch(`hl.dsp.window.center({ ${target} })`);
        }
    }

    Rectangle {
        id: sidebar

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: 220
        color: win.theme.color.surface

        Column {
            anchors.fill: parent
            anchors.margins: win.theme.space.m
            spacing: win.theme.space.xs

            ThemedText {
                text: I18n.tr("settings.title")
                font.pixelSize: win.theme.font.sizeL
                font.weight: Font.DemiBold
                bottomPadding: win.theme.space.m
            }

            Repeater {
                model: Settings.pages

                ListRow {
                    required property string modelData
                    title: I18n.tr(`settings.page.${modelData}`)
                    selected: Settings.page === modelData
                    onClicked: Settings.page = modelData
                }
            }
        }
    }

    Flickable {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: sidebar.right
        anchors.right: parent.right
        contentHeight: page.implicitHeight + win.theme.space.xl * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Loader {
            id: page

            x: win.theme.space.xl
            y: win.theme.space.xl
            // Readable line length even in a very wide window.
            width: Math.min(parent.width - win.theme.space.xl * 2, 900)
            source: `${Settings.page[0].toUpperCase()}${Settings.page.slice(1)}Page.qml`
        }
    }
}
