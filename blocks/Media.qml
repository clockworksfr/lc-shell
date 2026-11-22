import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme

// Active MPRIS player. Hidden when there is none.
// Left click: play/pause, right click: next, middle click: switch player.
// Options: maxWidth (px, default 400).
ThemedText {
    id: root

    property ShellScreen screen
    property var options: ({})

    readonly property var player: Players.active
    readonly property bool shown: player !== null

    readonly property string track: [player?.trackArtist, player?.trackTitle].filter(s => !!s).join(" — ") || player?.identity || ""

    width: Math.min(implicitWidth, options.maxWidth ?? 400)
    elide: Text.ElideRight
    text: `${player?.isPlaying ? "▶" : "⏸"}  ${track}`
    color: player?.isPlaying ? theme.color.ink : theme.color.soft

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                Players.togglePlaying();
            else if (mouse.button === Qt.RightButton)
                Players.next();
            else
                Players.cycle();
        }
    }
}
