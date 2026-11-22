import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Synced lyrics: the current line large, neighbours fading out, scrolling
// with the song. Plain (unsynced) lyrics scroll freely.
Item {
    id: root

    property ShellScreen screen
    property var options: ({})
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

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
        preferredHighlightBegin: height / 2 - root.theme.font.sizeL
        preferredHighlightEnd: height / 2 + root.theme.font.sizeL
        highlightRangeMode: ListView.StrictlyEnforceRange
        highlightMoveDuration: root.theme.motion.duration * 2
        spacing: root.theme.space.s

        delegate: ThemedText {
            required property var modelData
            required property int index
            readonly property int distance: Math.abs(index - Lyrics.index)

            width: list.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: modelData.text || "♪"
            font.pixelSize: distance === 0 ? root.theme.font.sizeL : root.theme.font.sizeM
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
            color: root.theme.color.soft
        }
    }
}
