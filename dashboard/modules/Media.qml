import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Active player by shape: tiny = cover + play; narrow = cover, title,
// play; wide / strip = cover, title / artist, progress, transport; box /
// tall = cover on top, title, transport. Themes without cover art (facade,
// modulaire) show the track in their display (VFD, amber LCD). Progress
// and times only for a real length (not streams). A live spectrum (cava)
// fills the room left while playing.
ModuleBase {
    id: root

    readonly property var player: Players.active
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0
    readonly property bool timed: (player?.lengthSupported ?? false) && length > 0 && length < 86400 && position <= length + 2
    readonly property bool art: theme.style.cover !== "none"

    function time(seconds: real): string {
        const s = Math.max(0, Math.round(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }

    ThemedText {
        anchors.centerIn: parent
        visible: !root.player
        text: I18n.tr("media.noPlayer")
        font.pixelSize: root.t3
        color: root.theme.color.soft
    }

    // Title, artist (in the theme's display when it has no cover art).
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
                font.pixelSize: track.m.t2 * (track.big ? 1.2 : 1)
                font.weight: Font.DemiBold
                color: track.ink
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: track.m.player?.trackArtist ?? ""
                font.pixelSize: track.m.t3
                color: track.soft
            }

            ThemedText {
                visible: track.m.timed && track.big
                text: `${track.m.time(track.m.position)} / ${track.m.time(track.m.length)}`
                font.pixelSize: track.m.t4
                font.features: ({ "tnum": 1 })
                color: track.soft
            }
        }
    }

    component Transport: Row {
        id: transport

        property var m
        property real size: 56
        property bool full: true

        spacing: transport.size * 0.25

        ModuleButton {
            visible: transport.full
            icon: "skip_previous"
            legend: "PREV"
            size: transport.size * 0.85
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.previous()
        }
        ModuleButton {
            icon: transport.m.player?.isPlaying ? "pause" : "play_arrow"
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

    // tiny / narrow.
    Column {
        visible: !!root.player && (root.shape === "tiny" || root.shape === "narrow")
        anchors.centerIn: parent
        width: parent.width
        spacing: root.gap

        Cover {
            anchors.horizontalCenter: parent.horizontalCenter
            source: root.player?.trackArtUrl ?? ""
            size: Math.min(root.cw * 0.8, root.ch * (root.shape === "tiny" ? 0.6 : 0.45))
        }

        Track {
            m: root
            visible: root.shape === "narrow" || !root.art
            width: parent.width
        }

        Transport {
            m: root
            anchors.horizontalCenter: parent.horizontalCenter
            full: false
            size: Math.max(root.theme.hit, root.t2 * 2)
        }
    }

    // wide / strip.
    Item {
        visible: !!root.player && (root.shape === "wide" || root.shape === "strip")
        anchors.fill: parent

        Cover {
            id: wideCover
            anchors.verticalCenter: parent.verticalCenter
            source: root.player?.trackArtUrl ?? ""
            size: Math.min(root.ch, root.cw * 0.36)
        }

        Item {
            anchors.left: wideCover.right
            anchors.leftMargin: wideCover.shown ? root.gap : 0
            anchors.right: parent.right
            height: parent.height

            Track {
                id: wideTrack
                m: root
                big: true
                width: root.shape === "strip" ? parent.width - wideTransport.width - root.gap : parent.width
                anchors.top: root.shape === "strip" ? undefined : parent.top
                anchors.verticalCenter: root.shape === "strip" ? parent.verticalCenter : undefined
            }

            // What's playing, live (cava): fills the room left.
            AudioSpectrum {
                visible: root.shape === "wide" && height >= 24 && (root.player?.isPlaying ?? false)
                anchors.top: wideTrack.bottom
                anchors.topMargin: root.gap
                anchors.bottom: wideGauge.visible ? wideGauge.top : wideTransport.top
                anchors.bottomMargin: root.gap
                width: parent.width
                count: Math.max(12, Math.min(32, Math.floor(width / 18)))
            }

            Gauge {
                id: wideGauge
                visible: root.timed && root.shape !== "strip"
                anchors.bottom: wideTransport.top
                anchors.bottomMargin: root.gap
                width: parent.width
                value: root.position / Math.max(1, root.length)
                color: root.theme.color.signal ?? root.theme.color.accent
                alarm: 2
            }

            Transport {
                id: wideTransport
                m: root
                anchors.bottom: root.shape === "strip" ? undefined : parent.bottom
                anchors.right: root.shape === "strip" ? parent.right : undefined
                anchors.verticalCenter: root.shape === "strip" ? parent.verticalCenter : undefined
                size: Math.max(root.theme.hit, Math.min(root.ch * (root.shape === "strip" ? 0.7 : 0.3), 72))
            }
        }
    }

    // box / tall: cover on top.
    Column {
        visible: !!root.player && (root.shape === "box" || root.shape === "tall")
        anchors.fill: parent
        spacing: root.gap

        Cover {
            anchors.horizontalCenter: parent.horizontalCenter
            source: root.player?.trackArtUrl ?? ""
            size: Math.min(root.cw, root.ch * 0.55)
        }

        Track {
            m: root
            big: true
            width: parent.width
        }

        AudioSpectrum {
            visible: root.ch >= 360 && (root.player?.isPlaying ?? false)
            width: parent.width
            height: Math.min(root.ch * 0.16, 90)
            count: Math.max(12, Math.min(32, Math.floor(width / 18)))
        }

        Gauge {
            visible: root.timed
            width: parent.width
            value: root.position / Math.max(1, root.length)
            color: root.theme.color.signal ?? root.theme.color.accent
            alarm: 2
        }

        Transport {
            m: root
            anchors.horizontalCenter: parent.horizontalCenter
            size: Math.max(root.theme.hit, Math.min(root.ch * 0.16, 72))
        }
    }
}
