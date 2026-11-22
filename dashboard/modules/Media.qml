import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Active player. S: cover, title / artist, play-pause, progress on the
// bottom edge; M: + source, elapsed / remaining time, previous / next;
// L: + output device and volume.
ModuleBase {
    id: root

    readonly property var player: Players.active
    readonly property real length: player?.length ?? 0
    // Streams report no length (or a bogus one): no times, no progress.
    readonly property bool timed: (player?.lengthSupported ?? false) && length > 0 && length < 86400 && position <= length + 2
    readonly property real position: player?.position ?? 0

    function time(seconds: real): string {
        const s = Math.max(0, Math.round(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    // MPRIS doesn't push position updates: poll while playing.
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

    Rectangle {
        id: cover

        visible: !!root.player
        width: Math.min(parent.height, parent.width * 0.42)
        height: width
        anchors.verticalCenter: parent.verticalCenter
        radius: root.theme.radius.tile
        color: root.theme.color.surface2
        clip: true

        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
    }

    Item {
        id: info

        visible: !!root.player
        anchors.left: cover.right
        anchors.leftMargin: root.gap
        anchors.right: parent.right
        height: parent.height

        Column {
            width: parent.width
            spacing: 2

            ThemedText {
                visible: root.tier !== "S"
                width: parent.width
                elide: Text.ElideRight
                label: true
                text: root.player?.identity ?? ""
                font.pixelSize: root.t4
                color: root.theme.color.soft
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                maximumLineCount: root.tier === "L" ? 2 : 1
                wrapMode: Text.Wrap
                text: root.player?.trackTitle || root.player?.identity || ""
                font.pixelSize: root.t2 * (root.tier === "S" ? 1 : 1.25)
                font.weight: Font.DemiBold
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                text: [root.player?.trackArtist ?? "", root.tier === "L" ? root.player?.trackAlbum ?? "" : ""].filter(s => !!s).join(" · ")
                font.pixelSize: root.t3
                color: root.theme.color.soft
            }
        }

        // Controls (bottom), progress with times above them (M / L).
        Column {
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: root.gap / 2

            Item {
                visible: root.tier !== "S" && root.timed
                width: parent.width
                height: root.t4 * 1.4

                ThemedText {
                    text: root.time(root.position)
                    font.pixelSize: root.t4
                    font.features: ({ "tnum": 1 })
                    color: root.theme.color.soft
                }

                ThemedText {
                    anchors.right: parent.right
                    text: `−${root.time(root.length - root.position)}`
                    font.pixelSize: root.t4
                    font.features: ({ "tnum": 1 })
                    color: root.theme.color.soft
                }
            }

            Rectangle {
                visible: root.tier !== "S" && root.timed
                width: parent.width
                height: Math.max(4, root.t4 * 0.35)
                radius: height / 2
                color: root.theme.color.surface3

                Rectangle {
                    width: parent.width * Math.min(1, root.position / Math.max(1, root.length))
                    height: parent.height
                    radius: parent.radius
                    color: root.theme.color.accent
                }
            }

            Row {
                spacing: root.gap

                Control {
                    visible: root.tier !== "S"
                    m: root
                    icon: "skip_previous"
                    onTapped: Players.previous()
                }
                Control {
                    m: root
                    icon: root.player?.isPlaying ? "pause" : "play_arrow"
                    primary: true
                    onTapped: Players.togglePlaying()
                }
                Control {
                    m: root
                    icon: "skip_next"
                    onTapped: Players.next()
                }

                // L: output volume.
                Row {
                    visible: root.tier === "L"
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.gap / 2

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "volume_up"
                        size: root.t3 * 1.3
                        color: root.theme.color.soft
                    }

                    Slider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(80, info.width - x - 4 * root.t2 * 2.6)
                        value: Audio.sink?.audio?.volume ?? 0
                        onMoved: value => Audio.setVolume(value)
                    }
                }
            }
        }
    }

    // S: progress on the module's bottom edge.
    Rectangle {
        visible: !!root.player && root.tier === "S" && root.timed
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -root.pad * 0.6
        x: cover.width + root.gap
        width: parent.width - x
        height: 3
        radius: 2
        color: root.theme.color.surface3

        Rectangle {
            width: parent.width * Math.min(1, root.position / Math.max(1, root.length))
            height: parent.height
            radius: parent.radius
            color: root.theme.color.accent
        }
    }

    component Control: Rectangle {
        id: control

        property var m
        property string icon
        property bool primary: false
        signal tapped

        width: Math.max(control.m.theme.hit, control.m.t2 * (primary ? 2.6 : 2.1))
        height: width
        radius: control.m.theme.radius.full
        color: primary ? control.m.theme.color.accent : area.pressed ? control.m.theme.color.surface2 : "transparent"
        border.width: primary ? 0 : 1
        border.color: control.m.theme.color.line

        Icon {
            anchors.centerIn: parent
            name: control.icon
            filled: true
            size: control.width * 0.5
            color: control.primary ? control.m.theme.color.onAccent : control.m.theme.color.ink
        }

        MouseArea {
            id: area
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: control.tapped()
        }
    }
}
