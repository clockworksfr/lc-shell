import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Active player. Every shape shows the track, a live spectrum (cava),
// the progress (a "live" bar for streams, which have no length) and the
// transport, laid out to fill the cell without overlaps:
//   tiny   track, progress, play + a small spectrum
//   narrow cover / track, spectrum filling, progress, play
//   wide   cover left; track, spectrum filling, progress, transport right
//   strip  one line: cover, track over the progress, spectrum, transport
//   box / tall  cover on top, track, spectrum filling, progress, transport
// Themes without cover art (facade, modulaire) show the track in their
// display (VFD, amber LCD).
ModuleBase {
    id: root

    readonly property var player: Players.active
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0
    readonly property bool timed: (player?.lengthSupported ?? false) && length > 0 && length < 86400 && position <= length + 2
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real buttonSize: Math.max(theme.hit, Math.min(72, m * (shape === "tiny" ? 0.34 : 0.24)))

    function time(seconds: real): string {
        const s = Math.max(0, Math.round(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }

    ThemedText {
        anchors.centerIn: parent
        visible: !root.player
        text: I18n.tr("media.noPlayer")
        font.pixelSize: root.t3
        color: root.theme.color.soft
    }

    // Title and artist (in the theme's display when it has no cover art).
    component Track: Display {
        id: track

        property var m
        property bool big: false

        tint: "amber"
        implicitHeight: col.implicitHeight + inset * 2

        Column {
            id: col
            width: parent.width
            spacing: 2

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: track.m.player?.trackTitle || track.m.player?.identity || ""
                font.family: track.m.theme.font.lyric ?? track.m.theme.font.family
                font.pixelSize: track.m.t2 * (track.big ? 1.15 : 0.9)
                font.weight: Font.DemiBold
                color: track.ink
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: track.m.player?.trackArtist ?? ""
                font.family: track.m.theme.font.lyric ?? track.m.theme.font.family
                font.pixelSize: track.m.t3 * (track.big ? 1 : 0.9)
                color: track.soft
            }
        }
    }

    // Progress with times, or a "live" bar for streams.
    component Progress: Column {
        id: progress

        property var m
        property bool times: true

        spacing: 3

        Gauge {
            width: parent.width
            value: progress.m.timed ? progress.m.position / Math.max(1, progress.m.length) : 1
            color: progress.m.timed ? (progress.m.theme.color.signal ?? progress.m.theme.color.accent) : Qt.alpha(progress.m.theme.color.soft, 0.6)
            alarm: 2
        }

        Item {
            visible: progress.times
            width: parent.width
            height: progress.m.t4 * 1.3

            ThemedText {
                text: progress.m.timed ? progress.m.time(progress.m.position) : I18n.tr("media.live")
                label: !progress.m.timed
                font.pixelSize: progress.m.t4
                font.features: ({ "tnum": 1 })
                color: progress.m.theme.color.soft
            }

            ThemedText {
                anchors.right: parent.right
                visible: progress.m.timed
                text: `−${progress.m.time(progress.m.length - progress.m.position)}`
                font.pixelSize: progress.m.t4
                font.features: ({ "tnum": 1 })
                color: progress.m.theme.color.soft
            }
        }
    }

    component Transport: Row {
        id: transport

        property var m
        property real size: 56
        property bool full: true

        spacing: transport.size * 0.22

        ModuleButton {
            visible: transport.full
            icon: "skip_previous"
            legend: "PREV"
            size: transport.size * 0.85
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.previous()
        }
        ModuleButton {
            icon: transport.m.playing ? "pause" : "play_arrow"
            legend: "PLAY"
            primary: true
            size: transport.size
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.togglePlaying()
        }
        ModuleButton {
            visible: transport.full
            icon: "skip_next"
            legend: "NEXT"
            size: transport.size * 0.85
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.next()
        }
    }

    // tiny: track, progress, play beside a small spectrum.
    ColumnLayout {
        visible: !!root.player && root.shape === "tiny"
        anchors.fill: parent
        spacing: root.gap / 2

        Track {
            m: root
            Layout.fillWidth: true
        }

        Progress {
            m: root
            times: false
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap / 2

            AudioSpectrum {
                Layout.fillWidth: true
                Layout.fillHeight: true
                count: 6
            }

            Transport {
                m: root
                full: false
                size: Math.min(root.buttonSize, parent.height)
            }
        }
    }

    // narrow / box / tall: a column; the spectrum takes the room left.
    ColumnLayout {
        visible: !!root.player && (root.shape === "narrow" || root.shape === "box" || root.shape === "tall")
        anchors.fill: parent
        spacing: root.gap / 1.5

        Cover {
            Layout.alignment: Qt.AlignHCenter
            source: root.player?.trackArtUrl ?? ""
            playing: root.playing
            size: Math.min(root.cw * (root.shape === "narrow" ? 0.9 : 0.7), root.ch * 0.4)
        }

        Track {
            m: root
            big: root.shape !== "narrow"
            Layout.fillWidth: true
        }

        AudioSpectrum {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 16
            count: Math.max(8, Math.min(32, Math.floor(width / 18)))
        }

        Progress {
            m: root
            Layout.fillWidth: true
        }

        Transport {
            m: root
            Layout.alignment: Qt.AlignHCenter
            full: root.cw >= root.buttonSize * 3.6
            size: root.buttonSize
        }
    }

    // wide: cover left; track, spectrum, progress, transport right.
    RowLayout {
        visible: !!root.player && root.shape === "wide"
        anchors.fill: parent
        spacing: root.gap

        Cover {
            Layout.alignment: Qt.AlignVCenter
            source: root.player?.trackArtUrl ?? ""
            playing: root.playing
            size: Math.min(root.ch, root.cw * 0.36)
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap / 1.5

            Track {
                m: root
                big: true
                Layout.fillWidth: true
            }

            AudioSpectrum {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 12
                count: Math.max(12, Math.min(32, Math.floor(width / 18)))
            }

            Progress {
                m: root
                Layout.fillWidth: true
            }

            Transport {
                m: root
                size: Math.min(root.buttonSize, root.ch * 0.26)
            }
        }
    }

    // strip: one line.
    RowLayout {
        visible: !!root.player && root.shape === "strip"
        anchors.fill: parent
        spacing: root.gap

        Cover {
            Layout.alignment: Qt.AlignVCenter
            source: root.player?.trackArtUrl ?? ""
            playing: root.playing
            size: root.ch
        }

        ColumnLayout {
            Layout.preferredWidth: root.cw * 0.3
            Layout.maximumWidth: root.cw * 0.3
            Layout.alignment: Qt.AlignVCenter
            spacing: root.gap / 2

            Track {
                m: root
                Layout.fillWidth: true
            }

            Progress {
                m: root
                times: root.ch > 110
                Layout.fillWidth: true
            }
        }

        AudioSpectrum {
            Layout.fillWidth: true
            Layout.fillHeight: true
            count: Math.max(12, Math.min(32, Math.floor(width / 18)))
        }

        Transport {
            m: root
            Layout.alignment: Qt.AlignVCenter
            size: Math.min(root.buttonSize, root.ch * 0.8)
        }
    }
}
