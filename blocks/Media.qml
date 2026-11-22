import QtQuick
import Quickshell
import qs.components
import qs.services

// Active MPRIS player. Hidden when there is none.
// Left click: play/pause, right click: next, middle click: switch player.
// Options: maxWidth (px, default 400). On a vertical bar: state glyph only.
TextBlock {
    id: root

    readonly property var player: Players.active
    readonly property bool shown: player !== null

    // "❚❚" rather than U+23F8, which renders as a color emoji.
    readonly property string glyph: player?.isPlaying ? "▶" : "❚❚"
    readonly property string track: [player?.trackArtist, player?.trackTitle].filter(s => !!s).join(" — ") || player?.identity || ""

    fullText: size === "compact" ? glyph : `${glyph}  ${track}`
    compactText: glyph
    width: vertical ? crossSize : Math.min(implicitWidth, options.maxWidth ?? (size === "extended" ? 560 : 360))
    horizontalAlignment: vertical ? Text.AlignHCenter : Text.AlignLeft
    color: player?.isPlaying ? theme.color.ink : theme.color.soft

    icon: player?.isPlaying ? "pause" : "play_arrow"
    iconFilled: true
    iconText: size === "compact" || vertical ? "" : track

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
