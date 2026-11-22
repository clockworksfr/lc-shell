import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

// Output volume. Click: mute, wheel: volume.
ThemedText {
    property ShellScreen screen
    property var options: ({})

    text: Audio.muted ? "muet" : `vol ${Math.round(Audio.volume * 100)} %`
    color: Audio.muted ? Theme.color.fgMuted : Theme.color.fg

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Audio.toggleMute()
        onWheel: wheel => wheel.angleDelta.y > 0 ? Audio.increment() : Audio.decrement()
    }
}
