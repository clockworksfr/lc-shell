import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services

// The most important thing going on, else the time: screen sharing (red),
// a microphone in use, the playing track, the time. Its card follows
// (cards/DynamicIslandCard: media or clock).
TextWidget {
    id: root

    readonly property var player: Players.active
    readonly property bool playing: player?.isPlaying ?? false
    // "sharing" | "mic" | "media" | "clock"
    readonly property string activity: Screens.sharing ? "sharing" : Audio.captureStreams.length > 0 ? "mic" : playing ? "media" : "clock"
    readonly property string track: [player?.trackTitle || player?.identity || "", player?.trackArtist ?? ""].filter(s => !!s).join(" — ")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string clockText: I18n.locale.toString(clock.date, "HH:mm")

    fullText: activity === "sharing" ? I18n.tr("island.sharing")
        : activity === "mic" ? I18n.tr("island.mic", { app: Audio.streamName(Audio.captureStreams[0]) })
        : activity === "media" ? (size === "compact" ? (player?.trackTitle || player?.identity || "") : track)
        : clockText
    compactText: activity === "clock" ? clockText : fullText
    color: activity === "sharing" ? theme.color.urgent : theme.color.ink
    width: vertical && crossSize > 0 ? crossSize : Math.min(implicitWidth, size === "extended" ? 520 : size === "compact" ? 180 : 360)

    icon: activity === "sharing" ? "screen_share" : activity === "mic" ? "mic" : activity === "media" ? "music_note" : ""
    iconText: fullText
    iconFilled: true

    MouseArea {
        anchors.fill: parent
        cursorShape: root.activity === "media" ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.activity === "media") Players.togglePlaying()
    }
}
