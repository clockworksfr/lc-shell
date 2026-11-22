import QtQuick
import Quickshell
import Quickshell.Io
import qs.clipboard
import qs.components
import qs.i18n

// Large view of one item: whole text (selectable, Ctrl+C copies the
// selection), image, color with its notations, links and file paths;
// details (source app, first copy, last use, times copied, tags).
Rectangle {
    id: root

    property var theme
    property var entry: null
    // Standalone (Space overlay): shadowless frame of its own.
    property bool framed: false

    // Escape in the text view.
    signal dismissed

    readonly property string kind: entry?.kind ?? "text"
    // Whole text: the index keeps only the start of long ones.
    property string fullText: ""
    readonly property string shownText: entry?.truncated && fullText ? fullText : (entry?.text ?? "")
    readonly property var desktop: (DesktopEntries.applications.values.length, entry?.app) ? DesktopEntries.heuristicLookup(entry.app) : null

    radius: theme.radius.tile
    color: framed ? theme.color.surface : theme.color.surface2
    border.width: 1
    border.color: theme.color.line
    clip: true

    onEntryChanged: {
        fullText = "";
        if (entry?.truncated)
            blob.path = Clipboard.blobPath(entry);
    }

    FileView {
        id: blob
        printErrors: false
        onLoaded: root.fullText = text()
    }

    // Clicks don't fall through (overlay closes on outside clicks).
    MouseArea {
        anchors.fill: parent
    }

    ThemedText {
        anchors.centerIn: parent
        visible: !root.entry
        text: I18n.tr("clip.noSelection")
        color: root.theme.color.soft
    }

    Item {
        id: content

        visible: !!root.entry
        anchors.fill: parent
        anchors.margins: root.theme.space.l

        // --- Details ---
        Column {
            id: details

            width: parent.width
            spacing: root.theme.space.xs

            Row {
                spacing: root.theme.space.s

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: ClipKinds.icon(root.kind)
                    color: Clipboard.tagColors[ClipKinds.color(root.kind)] ?? root.theme.color.soft
                }

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr(`clip.kind.${root.kind}`)
                    font.weight: Font.DemiBold
                }

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ClipKinds.summary(root.entry)
                    color: root.theme.color.soft
                    font.pixelSize: root.theme.font.sizeS
                }

                Repeater {
                    model: (root.entry?.tags ?? []).map(id => Clipboard.tag(id)).filter(t => !!t)

                    Rectangle {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: tagName.implicitWidth + root.theme.space.s * 2
                        height: 20
                        radius: 10
                        color: Qt.alpha(Clipboard.tagColors[modelData.color] ?? root.theme.color.soft, 0.25)

                        ThemedText {
                            id: tagName
                            anchors.centerIn: parent
                            text: parent.modelData.name
                            font.pixelSize: root.theme.font.sizeS
                        }
                    }
                }
            }

            ThemedText {
                width: parent.width
                elide: Text.ElideRight
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
                text: {
                    const e = root.entry;
                    if (!e)
                        return "";
                    const parts = [];
                    if (e.app)
                        parts.push(root.desktop?.name || e.app);
                    parts.push(I18n.tr("clip.firstCopied", { when: I18n.relativeTime(e.time) }));
                    if (e.last !== e.time)
                        parts.push(I18n.tr("clip.lastUsed", { when: I18n.relativeTime(e.last) }));
                    if ((e.count ?? 1) > 1)
                        parts.push(I18n.plural("clip.times", e.count));
                    if (e.pinned)
                        parts.push(I18n.tr("clip.pinned"));
                    return parts.join("  ·  ");
                }
            }
        }

        Item {
            id: body

            anchors.top: details.bottom
            anchors.topMargin: root.theme.space.m
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right

            // Text, code, link, file paths, character.
            Flickable {
                id: flick

                anchors.fill: parent
                visible: root.kind !== "image" && root.kind !== "color" && root.kind !== "char"
                contentWidth: width
                contentHeight: textView.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                TextEdit {
                    id: textView

                    width: flick.width
                    readOnly: true
                    selectByMouse: true
                    selectByKeyboard: true
                    textFormat: TextEdit.PlainText
                    wrapMode: root.kind === "code" ? TextEdit.NoWrap : TextEdit.Wrap
                    text: root.kind === "file" ? Clipboard.filePaths(root.entry).join("\n") : root.shownText.replace(/\t/g, "    ")
                    color: root.theme.color.ink
                    selectionColor: root.theme.color.accent
                    selectedTextColor: root.theme.color.onAccent
                    font.family: root.kind === "code" || root.kind === "file" ? root.theme.font.mono : root.theme.font.family
                    font.pixelSize: root.kind === "code" ? root.theme.font.sizeS + 1 : root.theme.font.sizeM

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape || (event.key === Qt.Key_Space && !selectedText)) {
                            root.dismissed();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier) && selectedText) {
                            Quickshell.clipboardText = selectedText;
                            event.accepted = true;
                        }
                    }
                }
            }

            Image {
                anchors.fill: parent
                visible: root.kind === "image"
                source: root.kind === "image" && root.entry?.file ? `file://${Clipboard.blobPath(root.entry)}` : ""
                sourceSize.width: 1600
                sourceSize.height: 1600
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Text {
                anchors.fill: parent
                visible: root.kind === "char"
                text: root.shownText.trim()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Math.min(height * 0.6, 160)
                color: root.theme.color.ink
            }

            // Color: swatch and its notations.
            Column {
                anchors.fill: parent
                visible: root.kind === "color"
                spacing: root.theme.space.m

                readonly property color value: Clipboard.colorValue(root.entry)

                Rectangle {
                    width: parent.width
                    height: Math.max(60, parent.height - notations.height - parent.spacing)
                    radius: root.theme.radius.control
                    color: parent.value
                    border.width: 1
                    border.color: root.theme.color.line
                }

                ThemedText {
                    id: notations

                    readonly property color c: parent.value

                    font.family: root.theme.font.mono
                    text: {
                        const hex = v => Math.round(v * 255).toString(16).padStart(2, "0").toUpperCase();
                        const pct = v => Math.round(v * 100);
                        return `#${hex(c.r)}${hex(c.g)}${hex(c.b)}${c.a < 1 ? hex(c.a) : ""}    rgb(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)})    hsl(${Math.round(Math.max(0, c.hslHue) * 360)}, ${pct(c.hslSaturation)}%, ${pct(c.hslLightness)}%)`;
                    }
                }
            }
        }
    }
}
