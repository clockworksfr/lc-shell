import QtQuick
import Quickshell
import qs.components
import qs.panels
import qs.services
import qs.theme

// Output volume. Left click: audio panel (volume, devices),
// middle click: mute, wheel: volume.
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    text: Audio.muted ? "muet" : `vol ${Math.round(Audio.volume * 100)} %`
    color: Audio.muted ? Theme.color.fgMuted : Theme.color.fg

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
