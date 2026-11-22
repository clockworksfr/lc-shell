import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Synced lyrics: the current line large, neighbours fading out, scrolling
// with the song; as many lines as the cell's shape holds (1 in a tiny
// cell, up to 7 in a tall one). Plain (unsynced) lyrics scroll freely.
ModuleBase {
    id: root

    readonly property int lines: shape === "tiny" ? 1 : shape === "strip" ? 2 : shape === "wide" ? 3 : Math.max(2, Math.min(7, Math.floor(ch / (t2 * 2.4))))
    readonly property real lineSize: Math.max(15, Math.min(ch / lines * 0.42, t2 * 1.3))

    Component.onCompleted: Lyrics.refCount++
    Component.onDestruction: Lyrics.refCount--

    // No lyrics: the icon over the state.
    Column {
        anchors.centerIn: parent
        width: parent.width
        visible: Lyrics.status !== "found" && Lyrics.status !== "plain"
        spacing: root.gap / 2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "lyrics"
            size: root.t2 * 2
            color: root.theme.color.soft
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: root.theme.color.soft
            text: I18n.tr(`lyrics.${Lyrics.status}`)
            font.pixelSize: root.t3
        }
    }

    ListView {
        id: list

        anchors.fill: parent
        visible: Lyrics.status === "found"
        clip: true
        interactive: false
        model: Lyrics.lines
        currentIndex: Math.max(0, Lyrics.index)
        // Keep the current line in the middle.
        preferredHighlightBegin: height / 2 - root.lineSize
        preferredHighlightEnd: height / 2 + root.lineSize
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: root.theme.motion.duration * 2
        spacing: root.lineSize * 0.35

        delegate: ThemedText {
            id: line

            required property var modelData
            required property int index
            readonly property int distance: Math.abs(index - Lyrics.index)

            width: list.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: modelData.text || "♪"
            font.family: root.theme.font.lyric ?? root.theme.font.family
            font.capitalization: root.theme.font.lyricCaps ? Font.AllUppercase : Font.MixedCase
            font.pixelSize: distance === 0 ? root.lineSize * 1.25 : root.lineSize
            font.weight: distance === 0 ? Font.DemiBold : Font.Normal
            color: distance === 0 ? root.theme.color.ink : root.theme.color.soft
            opacity: Math.max(0.25, 1 - distance * 0.22)

            // Matrix: a red dot before the sung line.
            Rectangle {
                visible: line.distance === 0 && root.theme.style.module === "matrix"
                anchors.right: parent.horizontalCenter
                anchors.rightMargin: line.contentWidth / 2 + line.font.pixelSize * 0.4
                anchors.verticalCenter: parent.verticalCenter
                width: line.font.pixelSize * 0.32
                height: width
                radius: width / 2
                color: root.theme.color.signal ?? root.theme.color.ink
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: root.theme.motion.duration
                }
            }
        }
    }

    Flickable {
        anchors.fill: parent
        visible: Lyrics.status === "plain"
        clip: true
        contentHeight: plain.implicitHeight

        ThemedText {
            id: plain
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: Lyrics.plainText
            font.pixelSize: root.t3
            color: root.theme.color.soft
        }
    }
}
