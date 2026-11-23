import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Cover, track, seekable progress with times, three lyric lines, controls.
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property var player: Players.active

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    Component.onCompleted: Lyrics.refCount++
    Component.onDestruction: Lyrics.refCount--

    spacing: theme.space.m

    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }

    ThemedText {
        visible: !root.player
        text: I18n.tr("media.noPlayer")
        color: root.theme.color.soft
    }

    Row {
        visible: !!root.player
        width: parent.width
        spacing: root.theme.space.m

        Rectangle {
            id: cover
            width: 84
            height: 84
            radius: root.theme.radius.control
            color: root.theme.color.surface2
            clip: true

            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            width: parent.width - cover.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            ThemedText {
                width: parent.width
                text: [root.player?.identity, Players.list.length > 1 ? `${Players.list.indexOf(root.player) + 1}/${Players.list.length}` : ""].filter(s => !!s).join(" · ")
                label: true
                color: root.theme.color.soft
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                text: root.player?.trackTitle || root.player?.identity || ""
                font.weight: Font.DemiBold
                font.pixelSize: root.theme.font.sizeL
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                visible: !!root.player?.trackAlbum
                text: root.player?.trackAlbum ?? ""
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
                elide: Text.ElideRight
            }
        }
    }

    // Progress: click to seek.
    Column {
        visible: (root.player?.lengthSupported ?? false) && root.player.length > 0 && root.player.length < 86400
        width: parent.width
        spacing: root.theme.space.xs

        Rectangle {
            width: parent.width
            height: 6
            radius: root.theme.radius.full
            color: root.theme.color.surface2

            Rectangle {
                width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                height: parent.height
                radius: parent.radius
                color: root.theme.color.accent
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                enabled: root.player?.canSeek ?? false
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => root.player.position = Math.max(0, Math.min(1, (mouse.x - 8) / (width - 16))) * root.player.length
            }
        }

        Item {
            width: parent.width
            implicitHeight: elapsed.implicitHeight

            ThemedText {
                id: elapsed
                text: root.time(root.player?.position ?? 0)
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
                font.features: ({ "tnum": 1 })
            }

            ThemedText {
                anchors.right: parent.right
                text: `-${root.time((root.player?.length ?? 0) - (root.player?.position ?? 0))}`
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
                font.features: ({ "tnum": 1 })
            }
        }
    }

    // Lyrics: previous, current, next line.
    Column {
        visible: Lyrics.status === "found" && Lyrics.index >= 0
        width: parent.width
        spacing: 2

        Repeater {
            model: [-1, 0, 1]

            ThemedText {
                required property int modelData
                readonly property var line: Lyrics.lines[Lyrics.index + modelData]

                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: line ? (line.text || "♪") : ""
                color: modelData === 0 ? root.theme.color.ink : root.theme.color.soft
                font.weight: modelData === 0 ? Font.DemiBold : Font.Normal
                opacity: modelData === 0 ? 1 : 0.7
            }
        }
    }

    Row {
        visible: !!root.player
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.theme.space.l

        // The module's buttons (theme pills), 40 px, play wider.
        Repeater {
            model: [
                { icon: "skip_previous", main: false, run: () => Players.previous() },
                { icon: root.player?.isPlaying ? "pause" : "play_arrow", main: true, run: () => Players.togglePlaying() },
                { icon: "skip_next", main: false, run: () => Players.next() }
            ]

            ModuleButton {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                icon: modelData.icon
                primary: modelData.main
                size: modelData.main ? 44 : 38
                onTapped: modelData.run()
            }
        }
    }
}
