import QtQuick
import Quickshell
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Synced lyrics: the current line large, neighbours fading out, moving up
// with the song. Always the previous and next lines at least (up to three
// on each side in tall cells), every line whole: lines wrap, and the size
// is the largest at which the whole block fits the cell. Plain (unsynced)
// lyrics scroll freely.
ModuleBase {
    id: root

    // Lines shown on each side of the current one.
    readonly property int side: shape === "tiny" || shape === "strip" || shape === "wide" ? 1 : Math.max(1, Math.min(3, Math.floor((ch / (t2 * 2.4) - 1) / 2)))
    readonly property int current: Math.max(0, Lyrics.index)
    // The lines in view, from `side` before the current one to `side` after.
    readonly property var shown: {
        const out = [];
        for (let i = current - side; i <= current + side; i++)
            if (i >= 0 && i < Lyrics.lines.length)
                out.push({ index: i, text: Lyrics.lines[i].text || "♪" });
        return out;
    }
    readonly property real spacingFactor: 0.3
    readonly property real maxSize: Math.max(15, t2 * 1.3)
    // Advance (at 100 px) of each shown line, from the measures below.
    property var advances: []
    // Largest size at which every shown line, wrapped, fits the height
    // (the current line is 1.25 × and bold).
    readonly property real lineSize: {
        const w = Math.max(1, cw), h = Math.max(1, ch);
        for (let size = Math.floor(maxSize); size > 9; size--) {
            let total = 0;
            for (let i = 0; i < shown.length; i++) {
                const big = shown[i].index === current;
                const px = big ? size * 1.25 : size;
                const rows = Math.max(1, Math.ceil((advances[i] ?? 0) * px / 100 * (big ? 1.06 : 1) * 1.08 / w));
                total += rows * px * 1.3 + (i > 0 ? size * spacingFactor : 0);
            }
            if (total <= h)
                return size;
        }
        return 10;
    }

    function measure(): void {
        const list = [];
        for (let i = 0; i < metrics.count; i++)
            list.push(metrics.itemAt(i)?.advance ?? 0);
        advances = list;
    }

    // Measures of the shown lines at 100 px (one line, no wrap).
    Repeater {
        id: metrics

        model: root.shown

        Item {
            required property var modelData
            readonly property real advance: tm.advanceWidth

            visible: false
            onAdvanceChanged: Qt.callLater(root.measure)

            TextMetrics {
                id: tm
                text: parent.modelData.text
                font.family: root.theme.font.lyric ?? root.theme.font.family
                font.capitalization: root.theme.font.lyricCaps ? Font.AllUppercase : Font.MixedCase
                font.weight: parent.modelData.index === root.current ? Font.DemiBold : Font.Normal
                font.pixelSize: 100
            }
        }
    }

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

    Item {
        id: synced

        anchors.fill: parent
        visible: Lyrics.status === "found"
        clip: true

        // A new line: the block comes up from one line lower.
        property real lift: 0
        Connections {
            target: root

            function onCurrentChanged(): void {
                synced.lift = root.lineSize * 1.6;
                rise.restart();
            }
        }
        NumberAnimation {
            id: rise
            target: synced
            property: "lift"
            to: 0
            duration: Motion.ms(root.theme, "base", "")
            easing.type: Easing.OutCubic
        }

        Column {
            width: parent.width
            y: (parent.height - height) / 2 + synced.lift
            spacing: root.lineSize * root.spacingFactor

            Repeater {
                model: root.shown

                ThemedText {
                    id: line

                    required property var modelData
                    readonly property int distance: Math.abs(modelData.index - root.current)

                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    lineHeight: 1.0
                    text: modelData.text
                    font.family: root.theme.font.lyric ?? root.theme.font.family
                    font.capitalization: root.theme.font.lyricCaps ? Font.AllUppercase : Font.MixedCase
                    font.pixelSize: distance === 0 ? root.lineSize * 1.25 : root.lineSize
                    font.weight: distance === 0 ? Font.DemiBold : Font.Normal
                    color: distance === 0 ? root.theme.color.ink : root.theme.color.soft
                    opacity: Math.max(0.3, 1 - distance * 0.22)

                    // Matrix: a red dot before the sung line (its first row).
                    Rectangle {
                        visible: line.distance === 0 && root.theme.style.module === "matrix"
                        x: Math.max(0, (line.width - Math.min(line.width, line.contentWidth)) / 2 - width - line.font.pixelSize * 0.3)
                        y: line.font.pixelSize * 0.62 - height / 2
                        width: line.font.pixelSize * 0.32
                        height: width
                        radius: width / 2
                        color: root.theme.color.signal ?? root.theme.color.ink
                    }
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
