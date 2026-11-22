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

    ThemedText {
        anchors.centerIn: parent
        width: parent.width
        visible: Lyrics.status !== "found" && Lyrics.status !== "plain"
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: root.theme.color.soft
        text: I18n.tr(`lyrics.${Lyrics.status}`)
        font.pixelSize: root.t3
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
            required property var modelData
            required property int index
            readonly property int distance: Math.abs(index - Lyrics.index)

            width: list.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: modelData.text || "♪"
            font.pixelSize: distance === 0 ? root.lineSize * 1.25 : root.lineSize
            font.weight: distance === 0 ? Font.DemiBold : Font.Normal
            color: distance === 0 ? root.theme.color.ink : root.theme.color.soft
            opacity: Math.max(0.25, 1 - distance * 0.22)

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
