import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.i18n
import qs.launcher
import qs.theme

// Settings app: a centered panel on the focused screen (layer surface, so
// Hyprland never tiles it over the user's windows), sidebar on the left:
// search (every setting, Index.qml) and the pages. Every change is applied live and written to the user settings.
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

        // Entrance: scale 0.98 → 1 and fade.
        anchors.fill: parent
        opacity: 0
        scale: Motion.reduced ? 1 : 0.98
        Component.onCompleted: frameEnter.start()

        ParallelAnimation {
            id: frameEnter
            NumberAnimation {
                target: frame
                property: "opacity"
                to: 1
                duration: Motion.ms(win.theme, "base", "")
            }
            NumberAnimation {
                target: frame
                property: "scale"
                to: 1
                duration: Motion.ms(win.theme, "base", "")
                easing.type: Motion.easing(win.theme)
            }
        }
        radius: win.theme.radius.panel
        color: win.theme.color.bg
        border.width: 1
        border.color: win.theme.color.line
        clip: true

        Keys.onEscapePressed: Settings.opened = false
        focus: true

        Rectangle {
            id: sidebar

            readonly property string query: Settings.query
            readonly property var results: {
                const q = Search.normalize(query.trim());
                if (!q)
                    return [];
                return Index.entries.filter(e => Search.normalize(I18n.tr(e.key)).includes(q) || (e.hint && Search.normalize(I18n.tr(e.hint)).includes(q))).slice(0, 12);
            }

            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: 240
            // The frame's rounded corners on the left (clip doesn't round):
            // a rounded fill, squared on its right side.
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: win.theme.radius.panel
                color: win.theme.color.surface
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: win.theme.radius.panel
                color: win.theme.color.surface
            }

            Column {
                id: sideHead
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: win.theme.space.m
                spacing: win.theme.space.xs

                ThemedText {
                    text: I18n.tr("settings.title")
                    font.pixelSize: win.theme.font.sizeL
                    font.weight: Font.DemiBold
                    bottomPadding: win.theme.space.s
                }

                TextField {
                    width: parent.width
                    text: Settings.query
                    placeholder: I18n.tr("settings.search")
                    onEdited: text => Settings.query = text
                    onCommitted: text => {
                        Settings.query = text;
                        if (sidebar.results.length)
                            Settings.show(sidebar.results[0].page, sidebar.results[0].key);
                    }
                }

            }

            // Search results (the query is set) or the pages, scrolling
            // when they don't fit; filets between groups of pages.
            Flickable {
                id: navFlick
                anchors.top: sideHead.bottom
                anchors.topMargin: win.theme.space.s
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: win.theme.space.m
                anchors.rightMargin: win.theme.space.m
                anchors.bottomMargin: win.theme.space.s
                contentHeight: navList.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

            // More pages below: a fade at the bottom of the list.
            Rectangle {
                parent: navFlick.parent
                anchors.left: navFlick.left
                anchors.right: navFlick.right
                anchors.bottom: navFlick.bottom
                height: 24
                z: 2
                visible: navFlick.contentY < navFlick.contentHeight - navFlick.height - 1
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.alpha(win.theme.color.surface, 0)
                    }
                    GradientStop {
                        position: 1
                        color: win.theme.color.surface
                    }
                }
            }

            Column {
                id: navList
                width: parent.width
                spacing: win.theme.space.xs

                ThemedText {
                    visible: !!sidebar.query.trim() && !sidebar.results.length
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: I18n.tr("settings.noResult")
                    color: win.theme.color.soft
                }

                Repeater {
                    model: sidebar.query.trim() ? sidebar.results : Settings.pages

                    // First page of a group: a filet above it.
                    Item {
                        id: navItem
                        required property var modelData
                        readonly property bool result: typeof modelData === "object"
                        readonly property bool groupStart: !result && ["notifications", "clipboard", "system"].includes(modelData)

                        width: parent.width
                        height: navRow.height + (groupStart ? win.theme.space.s * 2 + 1 : 0)

                        Rectangle {
                            visible: navItem.groupStart
                            x: win.theme.space.s
                            width: parent.width - win.theme.space.s * 2
                            height: 1
                            y: win.theme.space.s
                            color: win.theme.color.line
                        }

                        NavRow {
                            id: navRow
                            y: navItem.groupStart ? win.theme.space.s * 2 + 1 : 0
                            icon: navItem.result ? Settings.icons[navItem.modelData.page] : Settings.icons[navItem.modelData]
                            title: navItem.result ? I18n.tr(navItem.modelData.key) : I18n.tr(`settings.page.${navItem.modelData}`)
                            subtitle: navItem.result ? I18n.tr(`settings.page.${navItem.modelData.page}`) : ""
                            selected: !navItem.result && Settings.page === navItem.modelData
                            onClicked: navItem.result ? Settings.show(navItem.modelData.page, navItem.modelData.key) : Settings.page = navItem.modelData
                        }
                    }
                }
            }
            }
        }

        // The page's title, in the header band (left of the ×).
        ThemedText {
            x: sidebar.width + win.theme.space.xl
            y: (win.theme.space.s * 2 + 32 - height) / 2 + 2
            width: parent.width - x - 64
            text: I18n.tr(`settings.page.${Settings.page}`)
            font.pixelSize: 22
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Flickable {
            id: flick

            // Under a header band: the content never passes under the ×.
            anchors.top: parent.top
            anchors.topMargin: win.theme.space.s * 2 + 32
            anchors.bottom: parent.bottom
            anchors.left: sidebar.right
            anchors.right: parent.right
            contentHeight: page.implicitHeight + win.theme.space.s + win.theme.space.xl
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            // Wheel scrolling (see the MouseArea over it): notches add up to
            // a target the content glides to.
            property real target: 0
            readonly property real maxY: Math.max(0, contentHeight - height)

            function scrollBy(dy: real, smooth: bool): void {
                // From the target while gliding (fast spins add up), from
                // where it is otherwise.
                const from = glide.running ? target : contentY;
                target = Math.max(0, Math.min(maxY, from + dy));
                if (smooth) {
                    glide.from = contentY;
                    glide.to = target;
                    glide.restart();
                } else {
                    glide.stop();
                    contentY = target;
                }
            }

            NumberAnimation {
                id: glide
                target: flick
                property: "contentY"
                duration: 160
                easing.type: Easing.OutCubic
            }

            Loader {
                id: page

                x: win.theme.space.xl
                y: win.theme.space.s
                // Readable line length even in a very wide window.
                width: Math.min(parent.width - win.theme.space.xl * 2, 900)
                source: `${Settings.page[0].toUpperCase()}${Settings.page.slice(1)}Page.qml`

                // Page change: fade in with a small rise.
                onLoaded: {
                    opacity = 0;
                    pageShift.from = win.theme.space.s + Motion.travel(8);
                    pageEnter.start();
                }

                ParallelAnimation {
                    id: pageEnter
                    NumberAnimation {
                        target: page
                        property: "opacity"
                        to: 1
                        duration: Motion.ms(win.theme, "fast", "")
                    }
                    NumberAnimation {
                        id: pageShift
                        target: page
                        property: "y"
                        to: win.theme.space.s
                        duration: Motion.ms(win.theme, "base", "")
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        // The wheel over the pages, ahead of Flickable's own short steps:
        // ~100 px a notch, gliding (a free-spinning wheel goes fast and
        // smooth both ways); touchpads follow the fingers. Clicks pass.
        MouseArea {
            anchors.fill: flick
            acceptedButtons: Qt.NoButton
            onWheel: wheel => {
                if (wheel.pixelDelta.y !== 0)
                    flick.scrollBy(-wheel.pixelDelta.y, false);
                else
                    flick.scrollBy(-wheel.angleDelta.y / 120 * 100, true);
                wheel.accepted = true;
            }
        }

        // The border (Hyprland's width and the theme's window color), over
        // the sidebar.
        WindowBorder {
            radius: win.theme.radius.panel
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

    // A setting pointed out by the search: scrolled into view.
    Connections {
        target: Settings

        function onReveal(item: Item): void {
            Qt.callLater(() => {
                const y = item.mapToItem(flick.contentItem, 0, 0).y;
                flick.contentY = Math.max(0, Math.min(y - flick.height / 3, flick.contentHeight - flick.height));
            });
        }
    }

    component NavRow: Rectangle {
        id: row

        property string icon
        property string title
        property string subtitle
        property bool selected: false

        signal clicked

        width: parent?.width ?? 0
        height: Math.max(win.theme.hit + 8, subtitle ? 48 : 38)
        radius: win.theme.radius.control
        color: selected ? Qt.alpha(win.theme.color.accent, 0.16) : rowArea.containsMouse ? win.theme.color.surface2 : "transparent"

        Row {
            anchors.verticalCenter: parent.verticalCenter
            x: win.theme.space.s
            width: parent.width - win.theme.space.s * 2
            spacing: win.theme.space.s

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: row.icon
                size: 20
                filled: row.selected
                color: row.selected ? win.theme.color.accent : win.theme.color.soft
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 28

                ThemedText {
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.title
                    font.weight: row.selected ? Font.DemiBold : Font.Normal
                }

                ThemedText {
                    visible: !!row.subtitle
                    width: parent.width
                    elide: Text.ElideRight
                    text: row.subtitle
                    color: win.theme.color.soft
                    font.pixelSize: win.theme.font.sizeS
                }
            }
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }
    }
}
