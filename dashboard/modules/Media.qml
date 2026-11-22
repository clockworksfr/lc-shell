import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Active player. Every shape shows the track, a live spectrum (cava),
// the progress (a "live" bar for streams, which have no length) and the
// transport, laid out to fill the cell without overlaps:
//   tiny   track, progress, play + a small spectrum
//   narrow cover / track, spectrum filling, progress, play
//   wide   cover left; track, spectrum filling, progress, transport under
//   strip  one line: cover, track over the progress, spectrum, transport
//   box / tall  cover on top, track, spectrum filling, progress, transport
// Themes without cover art (facade, modulaire) show the track in their
// display (VFD, amber LCD).
ModuleBase {
    id: root

    readonly property var player: Players.active

    // Source menu: automatic, or one player pinned by hand. From the chip in
    // the title row (touch) or a right click anywhere on the module.
    function openSources(item: Item): void {
        const p = item.mapToItem(null, item.width / 2, item.height);
        sources.openAt(p.x, p.y);
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -root.pad
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            const p = mapToItem(null, mouse.x, mouse.y);
            sources.openAt(p.x, p.y);
        }
    }

    MenuPopup {
        id: sources

        host: root.QsWindow.window
        actions: [
            { id: "auto", text: I18n.tr("media.source.auto"), check: "radio", checked: !Players.locked },
            ...Players.list.map((p, i) => ({ id: `${i}`, text: p.identity || p.desktopEntry || "?", check: "radio", checked: Players.locked && Players.pinned === p }))
        ]
        onPicked: id => id === "auto" ? Players.auto() : Players.choose(Players.list[parseInt(id)])
    }

    // The chip in the title row: current source; a lock when pinned.
    Item {
        id: chip

        parent: root
        visible: root.inner.y > root.pad + 1 && (Players.list.length > 1 || Players.locked)
        x: root.width - width - 14
        y: 3
        width: chipRow.implicitWidth + 22
        height: 30

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: chipArea.containsMouse || chipArea.pressed ? root.theme.color.surface3 : "transparent"
            border.width: 1
            border.color: root.theme.color.line
        }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: Players.locked
                name: "push_pin"
                filled: true
                size: 16
                color: root.theme.color.accent
            }

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                label: true
                text: `${root.player?.identity ?? I18n.tr("media.source.title")}${Players.locked ? "" : ` · ${I18n.tr("media.source.autoShort")}`}`
                // The size of the menu's text it opens.
                font.pixelSize: 15
                color: root.theme.color.ink
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: "expand_more"
                size: 18
                color: root.theme.color.soft
            }
        }

        // A bigger target than the chip (touch).
        MouseArea {
            id: chipArea
            anchors.fill: parent
            anchors.margins: -12
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openSources(chip)
        }
    }
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0
    readonly property bool timed: (player?.lengthSupported ?? false) && length > 0 && length < 86400 && position <= length + 2
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real buttonSize: Math.max(theme.hit, Math.min(72, m * (shape === "tiny" ? 0.34 : 0.24)))
    // Matrix keys are pills (1.5 × as wide as tall).
    readonly property real keyAspect: theme.style.module === "matrix" ? 1.5 : 1
    // Controls go under the track in wide cells (design); strips keep one
    // line (cover, track, spectrum, controls).
    readonly property bool stacked: shape === "wide"

    function time(seconds: real): string {
        const s = Math.max(0, Math.round(seconds));
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }

    ThemedText {
        anchors.centerIn: parent
        visible: !root.player
        text: I18n.tr("media.noPlayer")
        font.pixelSize: root.t3
        color: root.theme.color.soft
    }

    // Where things go: facade puts the spectrum and the progress inside its
    // VFD, modulaire the progress on its amber screen (oscilloscope under
    // it); matrix shows the sound on the ring around its disc instead of
    // columns (but in strips and tiny cells, which have no disc).
    readonly property string screenKind: theme.style.display ?? "none"
    readonly property bool spectrumInside: screenKind === "vfd"
    readonly property bool progressInside: screenKind !== "none"
    readonly property bool ringShowsSound: theme.style.cover === "disc"

    // Title and artist, in the theme's display where it has one (with the
    // spectrum and / or the progress inside it, see above).
    component Track: Display {
        id: track

        property var m
        property bool big: false
        property bool withSpectrum: false
        property bool withProgress: false

        tint: "amber"
        implicitHeight: col.implicitHeight + inset * 2

        ColumnLayout {
            id: col
            anchors.fill: parent
            spacing: 2

            ThemedText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                text: track.m.player?.trackTitle || track.m.player?.identity || ""
                font.family: track.textFont
                font.capitalization: track.caps
                font.pixelSize: track.m.t2 * (track.big ? 1.15 : 0.9)
                font.weight: Font.DemiBold
                color: track.ink
            }

            ThemedText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: track.m.player?.trackArtist ?? ""
                font.family: track.textFont
                font.capitalization: track.caps
                font.pixelSize: track.m.t3 * (track.big ? 1 : 0.9)
                color: track.soft
            }

            AudioSpectrum {
                visible: track.withSpectrum
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 4
                count: Math.max(8, Math.min(32, Math.floor(width / 14)))
            }

            Progress {
                visible: track.withProgress
                m: track.m
                ink: track.ink
                Layout.fillWidth: true
                Layout.topMargin: 4
            }
        }
    }

    // Progress with times, or a "live" bar for streams.
    component Progress: Column {
        id: progress

        property var m
        property bool times: true
        // Text color (inside a display: its ink).
        property color ink: m.theme.color.soft

        spacing: 3

        Gauge {
            width: parent.width
            value: progress.m.timed ? progress.m.position / Math.max(1, progress.m.length) : 1
            color: progress.m.timed ? (progress.m.theme.color.signal ?? progress.m.theme.color.accent) : Qt.alpha(progress.m.theme.color.soft, 0.6)
            alarm: 2
        }

        Item {
            visible: progress.times
            width: parent.width
            height: progress.m.t4 * 1.3

            ThemedText {
                text: progress.m.timed ? progress.m.time(progress.m.position) : I18n.tr("media.live")
                label: !progress.m.timed
                font.family: progress.m.theme.font.mono
                font.pixelSize: progress.m.t4
                font.features: ({ "tnum": 1 })
                // "Live" in the signal color where the theme has one.
                color: !progress.m.timed && (progress.m.theme.style.module === "facade" || progress.m.theme.style.module === "matrix") ? (progress.m.theme.color.signal ?? "#FFB547") : progress.ink
            }

            ThemedText {
                anchors.right: parent.right
                visible: progress.m.timed
                text: `−${progress.m.time(progress.m.length - progress.m.position)}`
                font.family: progress.m.theme.font.mono
                font.pixelSize: progress.m.t4
                font.features: ({ "tnum": 1 })
                color: progress.ink
            }
        }
    }

    component Transport: Row {
        id: transport

        property var m
        property real size: 56
        property bool full: true

        spacing: transport.size * 0.22

        ModuleButton {
            visible: transport.full
            icon: "skip_previous"
            legend: I18n.tr("media.prev")
            size: transport.size * 0.85
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.previous()
        }
        ModuleButton {
            icon: transport.m.playing ? "pause" : "play_arrow"
            legend: I18n.tr("media.play")
            primary: true
            size: transport.size
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.togglePlaying()
        }
        ModuleButton {
            visible: transport.full
            icon: "skip_next"
            legend: I18n.tr("media.next")
            size: transport.size * 0.85
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.next()
        }
    }

    // tiny: track, progress, play beside a small spectrum.
    ColumnLayout {
        visible: !!root.player && root.shape === "tiny"
        anchors.fill: parent
        spacing: root.gap / 2

        Track {
            m: root

            withSpectrum: root.spectrumInside

            withProgress: root.progressInside

            Layout.fillHeight: root.spectrumInside
            Layout.fillWidth: true
        }

        Progress {
            m: root

            visible: !root.progressInside
            times: false
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap / 2

            AudioSpectrum {

                visible: !root.spectrumInside
                Layout.fillWidth: true
                Layout.fillHeight: true
                count: 6
            }

            Transport {
                m: root
                full: false
                size: Math.min(root.buttonSize, parent.height)
            }
        }
    }

    // narrow / box / tall: a column; the spectrum takes the room left.
    ColumnLayout {
        visible: !!root.player && (root.shape === "narrow" || root.shape === "box" || root.shape === "tall")
        anchors.fill: parent
        spacing: root.gap / 1.5

        // The cover takes what the title, progress and keys leave (the
        // layout shrinks its slot first, so the keys never leave the cell);
        // hidden when too small.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            Layout.preferredHeight: root.ch * 0.4
            Layout.maximumHeight: root.ch * 0.4

            Cover {
                readonly property real room: Math.min(root.cw * (root.shape === "narrow" ? 0.9 : 0.7), parent.height)
                anchors.centerIn: parent
                visible: shown && room >= 48
                source: root.player?.trackArtUrl ?? ""
                playing: root.playing
                size: Math.max(0, room)
            }
        }

        Track {
            m: root

            withSpectrum: root.spectrumInside

            withProgress: root.progressInside

            Layout.fillHeight: root.spectrumInside
            // In a screen, a moderate title leaves room for the spectrum.
            big: root.shape !== "narrow" && !root.spectrumInside
            Layout.fillWidth: true
        }

        AudioSpectrum {

            visible: !root.spectrumInside && !root.ringShowsSound
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 16
            count: Math.max(8, Math.min(32, Math.floor(width / 18)))
        }

        // The ring shows the sound: the room left stays between the blocks.
        Item {
            visible: !root.spectrumInside && root.ringShowsSound
            Layout.fillHeight: true
        }

        Progress {
            m: root

            visible: !root.progressInside
            Layout.fillWidth: true
        }

        Transport {
            m: root
            Layout.alignment: Qt.AlignHCenter
            full: root.cw >= root.buttonSize * 3.6 * root.keyAspect
            size: Math.min(root.buttonSize, root.ch * 0.2, root.cw / (3.6 * root.keyAspect))
        }
    }

    // wide: cover left; track, spectrum, progress, transport under one
    // another.
    RowLayout {
        visible: !!root.player && root.stacked
        anchors.fill: parent
        spacing: root.gap

        Cover {
            Layout.alignment: Qt.AlignVCenter
            source: root.player?.trackArtUrl ?? ""
            playing: root.playing
            size: Math.min(root.ch, root.cw * 0.36)
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.gap / 1.5

            Track {
                m: root

                withSpectrum: root.spectrumInside

                withProgress: root.progressInside

                Layout.fillHeight: root.spectrumInside
                big: true
                Layout.fillWidth: true
            }

            // The sound between the track and the progress, in every theme
            // (even where the cover's ring shows it too).
            AudioSpectrum {
                visible: !root.spectrumInside
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 12
                count: Math.max(12, Math.min(32, Math.floor(width / 18)))
            }

            Progress {
                m: root

                visible: !root.progressInside
                Layout.fillWidth: true
            }

            Transport {
                m: root
                // Never cut at the bottom: bounded by the height and width.
                size: Math.min(root.buttonSize, root.ch * 0.22, (root.cw * 0.64) / (3.9 * root.keyAspect))
            }
        }
    }

    // strip: one line.
    RowLayout {
        visible: !!root.player && root.shape === "strip" && !root.stacked
        anchors.fill: parent
        spacing: root.gap

        Cover {
            Layout.alignment: Qt.AlignVCenter
            source: root.player?.trackArtUrl ?? ""
            playing: root.playing
            size: root.ch
        }

        ColumnLayout {
            // The screen (with the spectrum inside) takes the line's room.
            Layout.fillWidth: root.spectrumInside
            Layout.preferredWidth: root.cw * 0.3
            Layout.maximumWidth: root.spectrumInside ? -1 : root.cw * 0.3
            Layout.fillHeight: root.spectrumInside
            Layout.alignment: Qt.AlignVCenter
            spacing: root.gap / 2

            Track {
                m: root

                withSpectrum: root.spectrumInside

                withProgress: root.progressInside

                Layout.fillHeight: root.spectrumInside
                Layout.fillWidth: true
            }

            Progress {
                m: root

                visible: !root.progressInside
                times: root.ch > 110
                Layout.fillWidth: true
            }
        }

        AudioSpectrum {

            visible: !root.spectrumInside
            Layout.fillWidth: true
            Layout.fillHeight: true
            count: Math.max(12, Math.min(32, Math.floor(width / 18)))
        }

        Transport {
            m: root
            Layout.alignment: Qt.AlignVCenter
            size: Math.min(root.buttonSize, root.ch * 0.8, root.cw * 0.28 / (3.6 * root.keyAspect))
        }
    }
}
