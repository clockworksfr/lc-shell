import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services

// Active MPRIS player. Hidden when there is none.
// Left click: play/pause, middle click: switch player; right click: its
// menu (play, next, previous, other player).
// Options: maxWidth (px, default 400). On a vertical bar: state glyph only.
TextWidget {
    id: root

    // Right-click menu (the bar's widget menu).
    readonly property var contextActions: [
        { id: "play", icon: player?.isPlaying ? "pause" : "play_arrow", text: I18n.tr(player?.isPlaying ? "ctx.pause" : "ctx.play") },
        { id: "next", icon: "skip_next", text: I18n.tr("ctx.next") },
        { id: "previous", icon: "skip_previous", text: I18n.tr("ctx.previous") },
        ...(Players.list.length > 1 ? [{ id: "cycle", icon: "tune", text: I18n.tr("ctx.otherPlayer") }] : [])
    ]
    function contextAction(id: string): void {
        if (id === "play")
            Players.togglePlaying();
        else if (id === "next")
            Players.next();
        else if (id === "previous")
            Players.previous();
        else if (id === "cycle")
            Players.cycle();
    }

    readonly property var player: Players.active
    readonly property bool shown: player !== null

    // "❚❚" rather than U+23F8, which renders as a color emoji.
    readonly property string glyph: player?.isPlaying ? "▶" : "❚❚"
    readonly property string track: [player?.trackArtist, player?.trackTitle].filter(s => !!s).join(" — ") || player?.identity || ""

    fullText: size === "compact" ? glyph : `${glyph}  ${track}`
    compactText: glyph
    width: vertical ? crossSize : Math.min(implicitWidth, options.maxWidth ?? (size === "extended" ? 560 : 360))
    horizontalAlignment: vertical ? Text.AlignHCenter : Text.AlignLeft
    // Modulaire: an amber LCD; Façade: a VFD (design "Barre").
    lcd: !vertical && size !== "compact" ? (theme.style.module === "modulaire" ? "amber" : theme.style.module === "facade" ? "vfd" : "") : ""
    readonly property color lcdInk: lcd === "vfd" ? theme.color.ink : "#FFB35A"
    color: lcd ? (player?.isPlaying ? lcdInk : Qt.alpha(lcdInk, 0.6)) : player?.isPlaying ? theme.color.ink : theme.color.soft

    icon: player?.isPlaying ? "pause" : "play_arrow"
    iconFilled: true
    iconText: size === "compact" || vertical ? "" : track

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton)
                Players.togglePlaying();
            else
                Players.cycle();
        }
    }
}
