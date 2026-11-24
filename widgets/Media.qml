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
    // "Title — Artist" (design "Média existant").
    readonly property string track: [player?.trackTitle, player?.trackArtist].filter(s => !!s).join(" — ") || player?.identity || ""
    readonly property bool extended: size === "extended" && !vertical && !lcd
    // Extended: a mini progress and the elapsed time after the title.
    readonly property real length: player?.lengthSupported && (player?.length ?? 0) > 0 && player.length < 86400 ? player.length : 0
    readonly property real ratio: length > 0 ? Math.max(0, Math.min(1, (player?.position ?? 0) / length)) : 0
    readonly property string elapsed: {
        const t = Math.max(0, Math.round(player?.position ?? 0));
        return `${Math.floor(t / 60)}:${String(t % 60).padStart(2, "0")}`;
    }
    readonly property real tailWidth: extended && length > 0 ? 34 + 8 + timeMetrics.advanceWidth + 8 : 0

    // The position moves while playing.
    Timer {
        interval: 1000
        repeat: true
        running: root.extended || root.vertical ? (root.player?.isPlaying ?? false) : false
        onTriggered: root.player.positionChanged()
    }
    TextMetrics {
        id: timeMetrics
        text: "88:88"
        font.family: root.theme.font.mono
        font.pixelSize: 11
    }

    fullText: size === "compact" ? glyph : `${glyph}  ${track}`
    compactText: glyph
    // The play / pause icon in every theme (Modulaire's LCD keeps its glyph).
    forceIcon: !lcd
    rightPadding: lcd ? 10 : tailWidth
    bottomPadding: lcd ? 3 : vertical ? 8 : 0
    // Text capped at 150 px (240 extended).
    width: vertical ? crossSize : Math.min(implicitWidth, lcd ? (options.maxWidth ?? 360) : leftPadding + rightPadding + (options.maxWidth ?? (size === "extended" ? 240 : 150)))
    horizontalAlignment: vertical ? Text.AlignHCenter : Text.AlignLeft
    lcd: theme.style.module === "modulaire" && !vertical && size !== "compact" ? "amber" : ""
    color: lcd ? (player?.isPlaying ? "#FFB35A" : Qt.alpha("#FFB35A", 0.6)) : player?.isPlaying ? theme.color.ink : theme.color.soft

    icon: player?.isPlaying ? "pause" : "play_arrow"
    iconFilled: true
    iconText: size === "compact" || vertical ? "" : track

    // Extended: mini progress (34 × 6) and the elapsed time.
    Row {
        visible: root.tailWidth > 0
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 6
            radius: 3
            color: root.theme.color.surface3

            Rectangle {
                width: parent.width * root.ratio
                height: parent.height
                radius: parent.radius
                color: root.theme.style.module === "matrix" ? root.theme.color.ink : root.theme.color.accent
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.elapsed
            font.family: root.theme.font.mono
            font.pixelSize: 11
            font.features: ({ "tnum": 1 })
            color: root.theme.color.soft
        }
    }

    // Vertical: a 24 × 4 progress under the icon.
    Rectangle {
        visible: root.vertical && root.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 24
        height: 4
        radius: 2
        color: root.theme.color.surface3

        Rectangle {
            width: parent.width * root.ratio
            height: parent.height
            radius: parent.radius
            color: root.theme.style.module === "matrix" ? root.theme.color.ink : root.theme.color.accent
        }
    }

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
