import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Media card: the theme's cover (84 px) beside the
// source, the title and "Artist · Album"; a seekable progress in the
// theme's language with its times; three lyric lines (left aligned; in
// the theme's screen in Façade / Modulaire); previous / play / next as the
// theme's pills or keys; the players as chips (tap: that one).
Column {
    id: root

    property var block
    property ShellScreen screen
    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string look: theme.style.module ?? "classic"
    readonly property var player: Players.active
    readonly property bool keys: look === "facade" || look === "modulaire"
    readonly property real ratio: Math.min(1, (player?.position ?? 0) / Math.max(1, player?.length ?? 1))

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    Component.onCompleted: Lyrics.refCount++
    Component.onDestruction: Lyrics.refCount--

    spacing: 12

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

    // Cover, then source / title / "Artist · Album".
    Row {
        visible: !!root.player
        width: parent.width
        spacing: 14

        Cover {
            id: cover
            // Façade cards: a plain square (the frame is the modules').
            forceLook: root.look === "facade" ? "square" : ""
            source: root.player?.trackArtUrl ?? ""
            playing: root.player?.isPlaying ?? false
            size: 84
        }

        Column {
            width: parent.width - (cover.visible ? cover.width + parent.spacing : 0)
            spacing: 4

            ThemedText {
                width: parent.width
                text: [root.player?.identity, Players.list.length > 1 ? `${Players.list.indexOf(root.player) + 1} / ${Players.list.length}` : ""].filter(s => !!s).join(" · ")
                font.family: root.theme.font.mono
                font.pixelSize: 11
                font.letterSpacing: 0.9
                font.capitalization: Font.AllUppercase
                color: root.theme.color.soft
                elide: Text.ElideRight
            }

            ThemedText {
                width: parent.width
                text: root.player?.trackTitle || root.player?.identity || ""
                font.weight: Font.DemiBold
                font.pixelSize: 18
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }

            ThemedText {
                width: parent.width
                visible: !!text
                text: [root.player?.trackArtist, root.player?.trackAlbum].filter(s => !!s).join(" · ")
                font.pixelSize: 13
                color: root.theme.color.soft
                elide: Text.ElideRight
            }
        }
    }

    // Progress in the theme's language; click to seek.
    Column {
        visible: (root.player?.lengthSupported ?? false) && root.player.length > 0 && root.player.length < 86400
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: root.look === "constellation" ? 8 : root.keys ? 10 : 6

            // Classic: a filled bar.
            Rectangle {
                visible: root.look === "classic"
                anchors.fill: parent
                radius: height / 2
                color: root.theme.color.surface2

                Rectangle {
                    width: parent.width * root.ratio
                    height: parent.height
                    radius: parent.radius
                    color: root.theme.color.accent
                }
            }

            // Constellation: a hairline, a gradient fill and a glowing head.
            Rectangle {
                visible: root.look === "constellation"
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 2
                radius: 1
                color: root.theme.color.line

                Rectangle {
                    width: parent.width * root.ratio
                    height: parent.height
                    radius: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: "transparent"
                        }
                        GradientStop {
                            position: 0.5
                            color: root.theme.color.accent2 ?? root.theme.color.accent
                        }
                        GradientStop {
                            position: 1
                            color: root.theme.color.accent
                        }
                    }
                }

                Rectangle {
                    x: parent.width * root.ratio - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: 12
                    color: Qt.alpha(root.theme.color.accent, 0.22)

                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: root.theme.color.ink
                    }
                }
            }

            // Façade / Modulaire: segments (VFD / LEDs); Matrix: dots.
            Row {
                id: segments
                visible: root.keys || root.look === "matrix"
                readonly property real dot: root.look === "matrix" ? 5.2 : root.look === "modulaire" ? 8 : 6
                readonly property real gap: root.look === "matrix" ? 11 - 5.2 : 3
                readonly property int count: Math.max(1, Math.floor((parent.width + gap) / (dot + gap)))
                anchors.verticalCenter: parent.verticalCenter
                spacing: gap

                Repeater {
                    model: segments.visible ? segments.count : 0

                    Rectangle {
                        required property int index
                        readonly property bool lit: (index + 0.5) / segments.count <= root.ratio
                        width: segments.dot
                        height: root.look === "matrix" ? 5.2 : 10
                        radius: root.look === "matrix" ? 2.6 : 1
                        color: root.look === "matrix" ? (lit ? root.theme.color.ink : root.theme.color.line)
                            : root.look === "modulaire" ? (lit ? "#46C46A" : "#3A2C22")
                            : (lit ? (root.theme.color.vfd ?? root.theme.color.ink) : Qt.alpha(root.theme.color.vfd ?? root.theme.color.ink, 0.085))
                    }
                }
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
                font.family: root.theme.font.mono
                font.pixelSize: 11
                font.features: ({ "tnum": 1 })
            }

            ThemedText {
                anchors.right: parent.right
                text: `−${root.time((root.player?.length ?? 0) - (root.player?.position ?? 0))}`
                color: root.theme.color.soft
                font.family: root.theme.font.mono
                font.pixelSize: 11
                font.features: ({ "tnum": 1 })
            }
        }
    }

    // Lyrics: previous, current, next line, left aligned (Façade / Modulaire:
    // in their screen).
    Item {
        visible: Lyrics.status === "found" && Lyrics.index >= 0
        width: parent.width
        height: lyricLines.implicitHeight + (lyricScreen.kind !== "none" ? 16 : 0)

        Display {
            id: lyricScreen
            anchors.fill: parent
            screen: root.keys
            tint: "green"
        }

        Column {
            id: lyricLines
            x: lyricScreen.kind !== "none" ? 10 : 0
            y: lyricScreen.kind !== "none" ? 8 : 0
            width: parent.width - 2 * x
            spacing: 3

            Repeater {
                model: [-1, 0, 1]

                ThemedText {
                    required property int modelData
                    readonly property var line: Lyrics.lines[Lyrics.index + modelData]
                    readonly property bool inScreen: lyricScreen.kind !== "none"

                    width: parent.width
                    elide: Text.ElideRight
                    text: line ? (line.text || "♪") : ""
                    font.family: inScreen ? lyricScreen.textFont : root.theme.font.family
                    font.capitalization: inScreen ? Font.AllUppercase : Font.MixedCase
                    font.pixelSize: modelData === 0 ? 15 : 13
                    font.weight: modelData === 0 ? Font.DemiBold : Font.Normal
                    color: inScreen ? lyricScreen.ink : modelData === 0 ? root.theme.color.ink : root.theme.color.soft
                    opacity: modelData === 0 ? 1 : inScreen ? (root.look === "modulaire" ? 0.42 : 0.38) : 0.65
                }
            }
        }
    }

    // Previous / play / next: the theme's pills or keys (40 px high).
    Row {
        visible: !!root.player
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Repeater {
            model: [
                { icon: "skip_previous", main: false, run: () => Players.previous() },
                { icon: root.player?.isPlaying ? "pause" : "play_arrow", main: true, run: () => Players.togglePlaying() },
                { icon: "skip_next", main: false, run: () => Players.next() }
            ]

            Rectangle {
                id: key
                required property var modelData
                readonly property bool main: modelData.main
                readonly property bool light: root.theme.variant === "light"

                readonly property color fill: root.look === "matrix" ? (main ? root.theme.color.ink : "transparent")
                    : main ? root.theme.color.accent : root.theme.color.surface2
                readonly property color glyph: root.look === "matrix" ? (main ? root.theme.color.surface : root.theme.color.ink)
                    : root.look === "modulaire" ? (main ? "white" : "#E5E8E1")
                    : root.look === "facade" ? (light ? "#1E2022" : "#E5E8E1")
                    : main ? root.theme.color.onAccent : root.theme.color.ink

                width: main ? 64 : 48
                height: 40
                radius: root.keys ? 4 : height / 2
                color: area.pressed ? Qt.darker(fill, 1.15) : area.containsMouse ? Qt.lighter(fill, 1.06) : fill
                border.width: root.look === "matrix" && !main ? 1 : 0
                border.color: root.theme.color.line
                gradient: root.look === "modulaire" && main ? orange
                    : root.keys ? (root.look === "facade" && light ? facadeLight : greyKey)
                    : root.look === "constellation" && main ? star : null

                Gradient {
                    id: greyKey
                    GradientStop {
                        position: 0
                        color: area.pressed ? "#4A4F52" : "#5E6366"
                    }
                    GradientStop {
                        position: 1
                        color: "#34383B"
                    }
                }
                Gradient {
                    id: facadeLight
                    GradientStop {
                        position: 0
                        color: "#F2F3EF"
                    }
                    GradientStop {
                        position: 1
                        color: "#C9CAC6"
                    }
                }
                Gradient {
                    id: orange
                    GradientStop {
                        position: 0
                        color: area.pressed ? "#D8783A" : "#F08A43"
                    }
                    GradientStop {
                        position: 1
                        color: "#C95B1B"
                    }
                }
                Gradient {
                    id: star
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: root.theme.color.accent
                    }
                    GradientStop {
                        position: 1
                        color: root.theme.color.accent2 ?? root.theme.color.accent
                    }
                }

                // Keys: a light top edge, a solid edge under them; Façade's
                // main key ringed in its screen color.
                Rectangle {
                    visible: root.keys
                    x: 2
                    y: 1
                    width: parent.width - 4
                    height: 1
                    color: key.light && root.look === "facade" ? "white" : "#30FFFFFF"
                }
                Rectangle {
                    visible: root.keys
                    x: 1
                    y: parent.height
                    width: parent.width - 2
                    height: 2
                    color: key.light && root.look === "facade" ? "#7D8083" : "black"
                }
                Rectangle {
                    visible: root.look === "facade" && key.main
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 3
                    color: "transparent"
                    border.width: 2
                    border.color: root.theme.color.ink
                }

                Icon {
                    anchors.centerIn: parent
                    name: key.modelData.icon
                    filled: true
                    size: 22
                    color: key.glyph
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: key.modelData.run()
                }
            }
        }
    }

    // The players: tap one to make it the active one.
    Row {
        visible: Players.list.length > 1
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6

        Repeater {
            model: Players.list

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool current: modelData === root.player

                width: chipText.implicitWidth + 20
                height: chipText.implicitHeight + 10
                radius: root.keys ? 3 : height / 2
                color: current && root.look !== "constellation" ? (root.look === "matrix" ? root.theme.color.ink : root.theme.color.accent) : "transparent"
                gradient: current && root.look === "constellation" ? chipStar : null
                border.width: current ? 0 : 1
                border.color: root.theme.color.line

                Gradient {
                    id: chipStar
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: root.theme.color.accent
                    }
                    GradientStop {
                        position: 1
                        color: root.theme.color.accent2 ?? root.theme.color.accent
                    }
                }

                ThemedText {
                    id: chipText
                    anchors.centerIn: parent
                    text: (chip.modelData.identity || chip.modelData.desktopEntry || "?") + (chip.modelData.isPlaying || chip.current ? "" : ` · ${I18n.tr("media.paused")}`)
                    font.family: root.look === "matrix" ? "Space Mono" : root.theme.font.family
                    font.pixelSize: root.look === "matrix" ? 11 : 12
                    font.weight: Font.Medium
                    font.capitalization: root.look === "matrix" || root.keys ? Font.AllUppercase : Font.MixedCase
                    font.letterSpacing: root.keys ? 1 : 0
                    color: chip.current ? (root.look === "matrix" ? root.theme.color.bg : root.theme.color.onAccent) : root.theme.color.soft
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Players.choose(chip.modelData)
                }
            }
        }
    }
}
