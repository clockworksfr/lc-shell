import QtQuick
import Quickshell
import qs.components
import qs.panels
import qs.services
import qs.theme
import qs.i18n

// Output volume. Left click: audio panel (volume, devices),
// middle click: mute, wheel: volume.
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    text: Audio.muted ? I18n.tr("common.muted") : I18n.tr("bar.volume", { value: Math.round(Audio.volume * 100) })
    color: Audio.muted ? theme.color.soft : theme.color.ink

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                Audio.toggleMute();
            else
                popup.visible = !popup.visible;
        }
        onWheel: wheel => wheel.angleDelta.y > 0 ? Audio.increment() : Audio.decrement()
    }

    BarPopup {
        id: popup
        anchorItem: root

        AudioPanel {}
    }
}
