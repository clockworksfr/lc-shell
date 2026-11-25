import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
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
// display (VFD, amber LCD). Big cells (tiers large / poster): cover,
// title / artist / album, player chips, a few lyric lines, the spectrum,
// progress, shuffle / previous / play / next / repeat and the volume
// (poster: the cover as hero with progress and keys under it).
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

    titleReserve: chip.visible ? chip.width + 14 : 0

    // The chip in the title row: current source; a lock when pinned.
    Item {
        id: chip

        parent: root
        // Beside the title only when there's room for both.
        visible: root.inner.y > root.pad + 1 && (Players.list.length > 1 || Players.locked) && root.width >= width + 150
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
    readonly property real keyAspect: theme.style.module === "matrix" || theme.style.module === "modulaire" ? 1.5 : 1
    // Controls go under the track in wide cells; strips keep one
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
    // Modulaire: no scope, the LCD fills the module.
    readonly property bool screenFills: spectrumInside || theme.style.module === "modulaire"
    // Modulaire: the keys span the module (thirds), 40–120 px high.
    readonly property bool modKeys: theme.style.module === "modulaire"
    readonly property real modKeyHeight: Math.round(clamp(40, Math.min(ch * 0.24, (cw - 2 * Math.max(8, Math.min(20, cw * 0.03))) / 3 / 1.5), 120))
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

            // Facade / modulaire: the source line on top of the screen.
            ThemedText {
                visible: track.kind !== "none"
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: `SRC ▸ ${track.m.player?.identity ?? ""}${Players.list.length > 1 ? ` ${Players.list.indexOf(track.m.player) + 1}/${Players.list.length}` : ""}`
                font.family: track.textFont
                font.capitalization: Font.AllUppercase
                font.pixelSize: track.m.t4
                color: track.ink
                opacity: 0.8
            }

            ThemedText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                text: track.m.player?.trackTitle || track.m.player?.identity || ""
                font.family: track.textFont
                font.capitalization: track.caps
                // A bit smaller: more of the title fits before the ellipsis.
                font.pixelSize: track.m.t2 * (track.big ? 0.98 : 0.8)
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
        // Modulaire: three equal keys across this width.
        property real span: 0
        readonly property real keyWidth: span > 0 ? (span - 2 * spacing) / 3 : 0

        spacing: span > 0 ? Math.max(8, Math.min(20, span * 0.03)) : transport.size * 0.22

        ModuleButton {
            visible: transport.full
            icon: "skip_previous"
            legend: I18n.tr("media.prev")
            keyWidth: transport.keyWidth
            size: transport.span > 0 || transport.m.modKeys ? transport.size : transport.size * 0.85
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.previous()
        }
        ModuleButton {
            icon: transport.m.playing ? "pause" : "play_arrow"
            legend: I18n.tr("media.play")
            primary: true
            keyWidth: transport.keyWidth
            size: transport.size
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.togglePlaying()
        }
        ModuleButton {
            visible: transport.full
            icon: "skip_next"
            legend: I18n.tr("media.next")
            keyWidth: transport.keyWidth
            size: transport.span > 0 || transport.m.modKeys ? transport.size : transport.size * 0.85
            anchors.verticalCenter: parent.verticalCenter
            onTapped: Players.next()
        }
    }

    // tiny: track, progress, play beside a small spectrum.
    ColumnLayout {
        visible: !!root.player && !root.large && root.shape === "tiny"
        anchors.fill: parent
        spacing: root.gap / 2

        Track {
            m: root
            // Modulaire: the play key alone.
            visible: root.theme.style.module !== "modulaire"

            withSpectrum: root.spectrumInside

            withProgress: root.progressInside

            Layout.fillHeight: root.screenFills
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

                visible: !root.screenFills
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
        visible: !!root.player && !root.large && (root.shape === "narrow" || root.shape === "box" || root.shape === "tall")
        anchors.fill: parent
        spacing: root.gap / 1.5

        // The cover takes what the title, progress and keys leave (the
        // layout shrinks its slot first, so the keys never leave the cell);
        // hidden when too small.
        Item {
            // No cover (modulaire): no slot either.
            visible: root.coverShown
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            Layout.preferredHeight: root.ch * 0.4
            Layout.maximumHeight: root.ch * 0.4

            Cover {
                readonly property real room: Math.min(root.cw * (root.shape === "narrow" ? 0.9 : 0.7), parent.height)
                anchors.centerIn: parent
                visible: root.coverShown && shown && room >= 48
                source: root.player?.trackArtUrl ?? ""
                playing: root.playing
                size: Math.max(0, room)
            }
        }

        Track {
            m: root

            withSpectrum: root.spectrumInside

            withProgress: root.progressInside

            Layout.fillHeight: root.screenFills
            // In a screen, a moderate title leaves room for the spectrum.
            big: root.shape !== "narrow" && !root.spectrumInside
            Layout.fillWidth: true
        }

        AudioSpectrum {

            visible: !root.screenFills && !root.ringShowsSound
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
            full: root.modKeys || root.cw >= root.buttonSize * 3.6 * root.keyAspect
            span: root.modKeys ? root.cw : 0
            size: root.modKeys ? root.modKeyHeight : Math.min(root.buttonSize, root.ch * 0.2, root.cw / (3.6 * root.keyAspect))
        }
    }

    // wide: cover left; track, spectrum, progress, transport under one
    // another.
    RowLayout {
        visible: !!root.player && !root.large && root.stacked
        anchors.fill: parent
        // Round covers (halo, ring of dots) need more room beside them.
        spacing: root.gap * (root.theme.style.cover === "sphere" || root.theme.style.cover === "disc" ? 2 : 1)

        Cover {
            visible: root.coverShown
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

                Layout.fillHeight: root.screenFills
                big: true
                Layout.fillWidth: true
            }

            // The sound between the track and the progress, in every theme
            // (even where the cover's ring shows it too).
            AudioSpectrum {
                visible: !root.screenFills
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
                span: root.modKeys ? parent.width : 0
                // Never cut at the bottom: bounded by the height and width.
                size: root.modKeys ? root.modKeyHeight : Math.min(root.buttonSize, root.ch * 0.22, (root.cw * 0.64) / (3.9 * root.keyAspect))
            }
        }
    }

    // strip: one line.
    RowLayout {
        visible: !!root.player && !root.large && root.shape === "strip" && !root.stacked
        anchors.fill: parent
        spacing: root.gap

        Cover {
            visible: root.coverShown
            Layout.alignment: Qt.AlignVCenter
            source: root.player?.trackArtUrl ?? ""
            playing: root.playing
            size: root.ch
        }

        ColumnLayout {
            // The screen (with the spectrum inside) takes the line's room.
            Layout.fillWidth: root.screenFills
            Layout.preferredWidth: root.cw * 0.3
            Layout.maximumWidth: root.screenFills ? -1 : root.cw * 0.3
            Layout.fillHeight: root.screenFills
            Layout.alignment: Qt.AlignVCenter
            spacing: root.gap / 2

            Track {
                m: root

                withSpectrum: root.spectrumInside

                withProgress: root.progressInside

                Layout.fillHeight: root.screenFills
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

            visible: !root.screenFills
            Layout.fillWidth: true
            Layout.fillHeight: true
            count: Math.max(12, Math.min(32, Math.floor(width / 18)))
        }

        Transport {
            m: root
            Layout.alignment: Qt.AlignVCenter
            // Modulaire strips: keys 80 % of the height, 1.5 : 1.
            size: root.modKeys ? Math.min(root.ch * 0.8, root.cw * 0.36 / 5) : Math.min(root.buttonSize, root.ch * 0.8, root.cw * 0.28 / (3.6 * root.keyAspect))
        }
    }

    // --- Big cells ---

    // Lyrics are fetched while a big player shows them.
    readonly property bool wantsLyrics: large && !!player
    onWantsLyricsChanged: Lyrics.refCount += wantsLyrics ? 1 : -1
    Component.onDestruction: if (wantsLyrics) Lyrics.refCount--
    readonly property int lyricLines: poster ? 5 : 3
    readonly property var lyricShown: {
        if (Lyrics.status !== "found")
            return [];
        const at = Math.max(0, Lyrics.index), out = [];
        const from = Math.max(0, Math.min(at - Math.floor(lyricLines / 2), Lyrics.lines.length - lyricLines));
        for (let i = from; i < Math.min(Lyrics.lines.length, from + lyricLines); i++)
            out.push({ text: Lyrics.lines[i].text || "♪", current: i === at });
        return out;
    }
    // The cover in every theme with one (Modulaire too).
    readonly property bool coverShown: theme.style.cover !== "none"
    readonly property real bigCover: !coverShown ? 0 : poster ? Math.min(ch * 0.7, cw * 0.42) : Math.min(ch, cw * 0.36)
    readonly property real bigKey: Math.max(hit, Math.min(96, t2 * 1.5))

    // Shuffle, previous, play, next, repeat.
    component BigKeys: Row {
        id: keys

        property var m
        spacing: keys.m.bigKey * 0.24

        ModuleButton {
            visible: keys.m.player?.shuffleSupported ?? false
            anchors.verticalCenter: parent.verticalCenter
            icon: "shuffle"
            size: keys.m.bigKey * 0.7
            opacity: keys.m.player?.shuffle ? 1 : 0.45
            onTapped: keys.m.player.shuffle = !keys.m.player.shuffle
        }
        ModuleButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_previous"
            legend: I18n.tr("media.prev")
            size: keys.m.bigKey * 0.85
            onTapped: Players.previous()
        }
        ModuleButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: keys.m.playing ? "pause" : "play_arrow"
            legend: I18n.tr("media.play")
            primary: true
            size: keys.m.bigKey
            onTapped: Players.togglePlaying()
        }
        ModuleButton {
            anchors.verticalCenter: parent.verticalCenter
            icon: "skip_next"
            legend: I18n.tr("media.next")
            size: keys.m.bigKey * 0.85
            onTapped: Players.next()
        }
        ModuleButton {
            visible: keys.m.player?.loopSupported ?? false
            anchors.verticalCenter: parent.verticalCenter
            icon: keys.m.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            size: keys.m.bigKey * 0.7
            opacity: (keys.m.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None ? 1 : 0.45
            onTapped: keys.m.player.loopState = keys.m.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : keys.m.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
        }
    }

    // The player's volume (when it has one).
    component BigVolume: Row {
        id: vol

        property var m
        visible: vol.m.player?.volumeSupported ?? false
        spacing: vol.m.gap * 0.6

        Icon {
            id: volIcon
            anchors.verticalCenter: parent.verticalCenter
            name: "volume_up"
            size: vol.m.t3 * 1.2
            color: vol.m.theme.color.soft
        }

        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: vol.width - volIcon.width - vol.spacing
            value: vol.m.player?.volume ?? 0
            onMoved: v => vol.m.player.volume = v
        }
    }

    Item {
        id: big

        visible: !!root.player && root.large
        anchors.fill: parent

        // Cover (left); poster: progress and keys under it.
        Column {
            id: bigLeft

            visible: root.coverShown
            width: root.bigCover
            anchors.verticalCenter: root.poster ? parent.verticalCenter : undefined
            spacing: root.gap

            Cover {
                source: root.player?.trackArtUrl ?? ""
                playing: root.playing
                size: root.bigCover
            }

            Progress {
                visible: root.poster
                m: root
                width: parent.width
            }

            BigKeys {
                visible: root.poster
                m: root
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        ColumnLayout {
            x: root.coverShown ? bigLeft.width + root.gap * 1.5 : 0
            width: parent.width - x
            height: parent.height
            spacing: root.gap * 0.7

            Track {
                m: root
                big: true
                withProgress: false
                withSpectrum: false
                Layout.fillWidth: true
            }

            ThemedText {
                Layout.fillWidth: true
                visible: !!root.player?.trackAlbum
                elide: Text.ElideRight
                text: root.player?.trackAlbum ?? ""
                font.pixelSize: root.t3
                color: root.theme.color.soft
            }

            // Players: the one shown first, tap another to pin it.
            Flow {
                Layout.fillWidth: true
                visible: Players.list.length > 1
                spacing: root.gap * 0.5

                Repeater {
                    model: [...Players.list].sort((a, b) => (b === root.player) - (a === root.player))

                    Rectangle {
                        required property var modelData
                        readonly property bool current: modelData === root.player
                        width: chipText.implicitWidth + root.t4 * 2
                        height: root.t4 * 2.2
                        radius: height / 2
                        color: current ? Qt.alpha(root.theme.color.signal ?? root.theme.color.accent, 0.16) : "transparent"
                        border.width: 1
                        border.color: current ? (root.theme.color.signal ?? root.theme.color.accent) : root.theme.color.line

                        ThemedText {
                            id: chipText
                            anchors.centerIn: parent
                            label: true
                            text: parent.modelData.identity || parent.modelData.desktopEntry || "?"
                            font.pixelSize: root.t4
                            color: parent.current ? root.theme.color.ink : root.theme.color.soft
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Players.choose(parent.modelData)
                        }
                    }
                }
            }

            // A few lyric lines, the sung one in ink.
            Column {
                Layout.fillWidth: true
                visible: root.lyricShown.length > 0
                spacing: root.gap * 0.25

                Repeater {
                    model: root.lyricShown

                    ThemedText {
                        required property var modelData
                        width: parent.width
                        elide: Text.ElideRight
                        text: modelData.text
                        font.family: root.theme.font.lyric ?? root.theme.font.family
                        font.capitalization: root.theme.font.lyricCaps ? Font.AllUppercase : Font.MixedCase
                        font.pixelSize: root.t3 * (modelData.current ? 1.15 : 1)
                        font.weight: modelData.current ? Font.DemiBold : Font.Normal
                        color: modelData.current ? root.theme.color.ink : root.theme.color.soft
                        opacity: modelData.current ? 1 : 0.6
                    }
                }
            }

            AudioSpectrum {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: root.t2
                count: root.poster ? 64 : Math.max(16, Math.min(48, Math.floor(width / 18)))
            }

            Progress {
                visible: !root.poster || !root.coverShown
                m: root
                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(bigKeys.height, bigVolume.height)

                BigKeys {
                    id: bigKeys
                    visible: !root.poster || !root.coverShown
                    m: root
                }

                BigVolume {
                    id: bigVolume
                    m: root
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(parent.width * 0.35, 420)
                }
            }
        }
    }
}
