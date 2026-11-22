import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.i18n
import qs.theme

// Settings app: a centered panel on the focused screen (layer surface, so
// Hyprland never tiles it over the user's windows), sidebar of pages on the
// left. Every change is applied live and written to the user settings.
// Close: the × button, Escape, or `settings close`. Clicking elsewhere keeps
// it open (to watch a change apply).
PanelWindow {
    id: win

    property var theme: Themes.resolve(Themes.themeFor("normal"), false, "normal")

    // Screen chosen at opening (not following focus afterwards).
    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    implicitWidth: Math.min(980, (screen?.width ?? 1200) - 64)
    implicitHeight: Math.min(720, (screen?.height ?? 900) - 96)
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lc-settings"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Component.onCompleted: screen = screen // freeze the binding

    Rectangle {
        id: frame

        anchors.fill: parent
        radius: win.theme.radius.panel
        color: win.theme.color.bg
        border.width: 1
        border.color: win.theme.color.line
        clip: true

        Keys.onEscapePressed: Settings.opened = false
        focus: true

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

        // Close.
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: win.theme.space.s
            width: 32
            height: 32
            radius: 16
            color: closeArea.containsMouse ? win.theme.color.surface3 : "transparent"

            Icon {
                anchors.centerIn: parent
                name: "close"
                size: 20
            }

            MouseArea {
                id: closeArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Settings.opened = false
            }
        }
    }
}
