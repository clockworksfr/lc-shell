import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.i18n
import qs.services
import qs.theme

// After "done" in the bar's edit mode: "Bar saved · Undo" for 8 s (time
// bar; paused while hovered). Undo puts the bars back as they were.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    property real remaining: 8000
    readonly property bool hovered: hover.hovered

    anchors.bottom: true
    margins.bottom: 48
    implicitWidth: row.implicitWidth + theme.space.m * 2
    implicitHeight: row.implicitHeight + theme.space.m * 2 + 4
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-toast"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Component.onCompleted: remaining = Math.max(0, BarEditor.toastUntil - Date.now())

    Timer {
        interval: 50
        repeat: true
        running: !win.hovered
        onTriggered: {
            win.remaining -= interval;
            if (win.remaining <= 0)
                BarEditor.toastUntil = 0;
        }
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        radius: win.theme.radius.panel
        color: win.theme.color.surface
        border.width: 1
        border.color: win.theme.color.line
        clip: true

        opacity: 0
        y: Motion.travel(12)
        Component.onCompleted: {
            opacity = 1;
            y = 0;
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.ms(win.theme, "fast", "")
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Motion.ms(win.theme, "base", "")
                easing.type: Motion.easing(win.theme)
            }
        }

        HoverHandler {
            id: hover
        }

        Row {
            id: row

            x: win.theme.space.m
            y: win.theme.space.m
            spacing: win.theme.space.m

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "check"
                size: 20
                color: win.theme.color.ok
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr("edit.saved")
            }

            Button {
                anchors.verticalCenter: parent.verticalCenter
                icon: "undo"
                text: I18n.tr("edit.undo")
                onClicked: BarEditor.revertSave()
            }

            Button {
                anchors.verticalCenter: parent.verticalCenter
                icon: "close"
                onClicked: BarEditor.toastUntil = 0
            }
        }

        // Time left.
        Rectangle {
            anchors.bottom: parent.bottom
            height: 3
            width: parent.width * win.remaining / 8000
            color: win.theme.color.accent
        }
    }
}
