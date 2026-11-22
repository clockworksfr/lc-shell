import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.theme
import qs.i18n

// Active player: cover, track, progress, controls (touch-sized).
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    readonly property var player: Players.active

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
        color: root.theme.color.soft
    }

    Row {
        anchors.fill: parent
        visible: !!root.player
        spacing: root.theme.space.m

        Rectangle {
            id: cover
            width: parent.height
            height: parent.height
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

        Column {
            width: parent.width - cover.width - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.space.s

            ThemedText {
                width: parent.width
                text: root.player?.trackTitle || root.player?.identity || ""
                font.pixelSize: root.theme.font.sizeL
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                color: root.theme.color.soft
                elide: Text.ElideRight
            }

            Rectangle {
                width: parent.width
                height: 4
                radius: root.theme.radius.full
                color: root.theme.color.surface2
                visible: root.player?.lengthSupported ?? false

                Rectangle {
                    width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                    height: parent.height
                    radius: parent.radius
                    color: root.theme.color.accent
                }
            }

            Row {
                spacing: root.theme.space.s

                Control {
                    glyph: "⏮"
                    onTapped: Players.previous()
                }
                Control {
                    glyph: root.player?.isPlaying ? "⏸" : "▶"
                    onTapped: Players.togglePlaying()
                }
                Control {
                    glyph: "⏭"
                    onTapped: Players.next()
                }
            }
        }
    }

    component Control: Rectangle {
        id: control

        property string glyph
        signal tapped

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

        width: Math.max(theme.hit, 36)
        height: width
        radius: theme.radius.full
        color: area.pressed ? theme.color.surface2 : "transparent"
        border.width: 1
        border.color: theme.color.line

        ThemedText {
            anchors.centerIn: parent
            text: control.glyph
            font.pixelSize: Math.round(control.width * 0.38)
        }

        MouseArea {
            id: area
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: control.tapped()
        }
    }
}
