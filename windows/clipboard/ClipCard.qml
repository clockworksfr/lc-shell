import QtQuick
import Quickshell
import qs.clipboard
import qs.components
import qs.i18n
import qs.theme

// One clipboard item as a card: header (kind, source app), preview by
// kind, footer (age, size, tags). The header pin toggles pinning.
Rectangle {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

    required property var entry
    property bool current: false
    // 1-9: shown as the Ctrl+n hint, 0 = none.
    property int number: 0
    // Smaller paddings and preview (narrow column layouts).
    property bool compact: false

    signal clicked(var mouse)
    signal doubleClicked
    signal hovered

    readonly property string kind: entry?.kind ?? "text"
    readonly property color kindColor: Clipboard.tagColors[ClipKinds.color(kind)] ?? theme.color.soft
    readonly property var entryTags: (entry?.tags ?? []).map(id => Clipboard.tag(id)).filter(t => !!t)
    readonly property string text: entry?.text ?? ""
    readonly property int pad: compact ? theme.space.s : theme.space.m

    readonly property int borderWidth: current ? 2 : 1

    radius: theme.radius.tile
    color: theme.color.surface2
    clip: true

    HoverHandler {
        id: hover
    }

    // --- Header ---
    Rectangle {
        id: header

        // Above the card's mouse area (the pin button), below the border.
        z: 1
        width: parent.width
        height: root.compact ? 28 : 34
        // Opaque: the filler below squares its bottom corners.
        color: Qt.tint(root.theme.color.surface2, Qt.alpha(root.kindColor, 0.18))
        radius: root.radius

        // Square bottom corners.
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.radius
            color: parent.color
            visible: parent.radius > 0
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: root.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.space.xs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: ClipKinds.icon(root.kind)
                size: 16
                color: root.kindColor
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.tr(`clip.kind.${root.kind}`)
                label: true
                color: root.theme.color.ink
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: root.pad
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.space.xs

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.number > 0
                text: `Ctrl ${root.number}`
                font.family: root.theme.font.mono
                font.pixelSize: root.theme.font.sizeS - 1
                color: root.theme.color.soft
            }

            // Pin toggle: shown when pinned, hovered or selected.
            Item {
                anchors.verticalCenter: parent.verticalCenter
                visible: !!root.entry?.pinned || hover.hovered || root.current
                width: 22
                height: 22

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: pinArea.containsMouse ? Qt.alpha(root.theme.color.ink, 0.12) : "transparent"
                }

                Icon {
                    anchors.centerIn: parent
                    name: "push_pin"
                    filled: !!root.entry?.pinned
                    size: 15
                    color: root.entry?.pinned || pinArea.containsMouse ? root.theme.color.accent : root.theme.color.soft
                }

                MouseArea {
                    id: pinArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.entry) Clipboard.togglePin(root.entry.id)
                }
            }

            AppIcon {
                id: appIcon

                readonly property var desktop: (DesktopEntries.applications.values.length, root.entry?.app) ? DesktopEntries.heuristicLookup(root.entry.app) : null

                anchors.verticalCenter: parent.verticalCenter
                visible: !!desktop?.icon
                name: desktop?.icon ?? ""
                source: desktop?.icon ? Quickshell.iconPath(desktop.icon, true) : ""
                size: 18
                background: root.theme.color.surface2
            }
        }
    }

    // --- Body ---
    Item {
        id: body

        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.pad
        anchors.topMargin: root.kind === "image" || root.kind === "color" ? 0 : root.pad
        anchors.bottomMargin: root.theme.space.xs
        clip: true

        Loader {
            anchors.fill: parent
            sourceComponent: {
                switch (root.kind) {
                case "image":
                    return imageBody;
                case "color":
                    return colorBody;
                case "link":
                    return linkBody;
                case "file":
                    return fileBody;
                case "char":
                    return charBody;
                case "code":
                    return codeBody;
                default:
                    return textBody;
                }
            }
        }
    }

    Component {
        id: textBody

        ThemedText {
            text: root.text.replace(/\t/g, "    ").slice(0, 1200)
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            verticalAlignment: Text.AlignTop
            maximumLineCount: Math.max(1, Math.floor(height / (font.pixelSize * 1.3)))
            textFormat: Text.PlainText
        }
    }

    Component {
        id: codeBody

        ThemedText {
            text: root.text.replace(/\t/g, "    ").split("\n").slice(0, 40).join("\n")
            font.family: root.theme.font.mono
            font.pixelSize: root.theme.font.sizeS
            verticalAlignment: Text.AlignTop
            textFormat: Text.PlainText
            clip: true
        }
    }

    Component {
        id: linkBody

        Column {
            spacing: root.theme.space.xs

            readonly property string url: root.text.trim()
            readonly property string host: url.replace(/^[a-z]+:\/\//i, "").replace(/^mailto:/i, "").replace(/^www\./i, "").split(/[/?#]/)[0]

            ThemedText {
                width: parent.width
                text: parent.host
                font.pixelSize: root.compact ? root.theme.font.sizeM : root.theme.font.sizeL
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                height: parent.height - y
                text: parent.url
                color: root.theme.color.soft
                font.pixelSize: root.theme.font.sizeS
                wrapMode: Text.WrapAnywhere
                elide: Text.ElideRight
                verticalAlignment: Text.AlignTop
                maximumLineCount: Math.max(1, Math.floor(height / (font.pixelSize * 1.3)))
                textFormat: Text.PlainText
            }
        }
    }

    Component {
        id: colorBody

        Item {
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: root.pad
                radius: 8
                color: Clipboard.colorValue(root.entry)
                border.width: 1
                border.color: root.theme.color.line

                ThemedText {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: root.theme.space.s
                    text: root.text.trim()
                    font.family: root.theme.font.mono
                    // Readable on the swatch.
                    color: parent.color.hslLightness > 0.55 ? "#111111" : "#F5F5F5"
                }
            }
        }
    }

    Component {
        id: imageBody

        Item {
            Image {
                anchors.fill: parent
                anchors.topMargin: root.pad
                source: root.entry?.file ? `file://${Clipboard.blobPath(root.entry)}` : ""
                sourceSize.width: 480
                sourceSize.height: 480
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                smooth: true
            }
        }
    }

    Component {
        id: fileBody

        Item {
            readonly property var paths: Clipboard.filePaths(root.entry)
            readonly property string first: paths[0] ?? ""
            readonly property bool picture: paths.length === 1 && Clipboard.imageExtensions.includes(first.split(".").pop().toLowerCase())

            Image {
                anchors.fill: parent
                visible: parent.picture
                source: parent.picture ? `file://${parent.first}` : ""
                sourceSize.width: 480
                sourceSize.height: 480
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            Column {
                anchors.fill: parent
                visible: !parent.picture
                spacing: 2

                Repeater {
                    model: parent.parent.paths.slice(0, 8)

                    Row {
                        required property string modelData
                        width: parent.width
                        spacing: root.theme.space.xs

                        Icon {
                            name: /\.[^/]+$/.test(parent.modelData) ? "description" : "folder_open"
                            size: 16
                            color: root.theme.color.soft
                        }

                        ThemedText {
                            width: parent.width - 20
                            text: parent.modelData.split("/").filter(s => s).pop() ?? parent.modelData
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }
        }
    }

    Component {
        id: charBody

        Text {
            text: root.text.trim()
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Math.min(height * 0.7, 72)
            color: root.theme.color.ink
        }
    }

    // --- Footer ---
    Item {
        id: footer

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.pad
        anchors.bottomMargin: root.compact ? root.theme.space.xs : root.theme.space.s
        height: 20

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - age.implicitWidth - root.theme.space.s
            spacing: root.theme.space.xs

            Repeater {
                id: tagDots
                model: root.entryTags

                Rectangle {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    color: Clipboard.tagColors[modelData.color] ?? root.theme.color.soft
                }
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, parent.width - tagDots.count * (10 + root.theme.space.xs))
                text: ClipKinds.summary(root.entry)
                elide: Text.ElideRight
                font.pixelSize: root.theme.font.sizeS
                color: root.theme.color.soft
            }
        }

        ThemedText {
            id: age
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.relativeTime(root.entry?.last ?? 0)
            font.pixelSize: root.theme.font.sizeS
            color: root.theme.color.soft
        }
    }

    // Drawn over the header so its corners stay whole.
    Rectangle {
        z: 2
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.current ? root.theme.color.accent : root.theme.color.line
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered()
        onClicked: mouse => root.clicked(mouse)
        onDoubleClicked: root.doubleClicked()
    }
}
