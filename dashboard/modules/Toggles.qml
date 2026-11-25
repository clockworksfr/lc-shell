import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.components.dashboard
import qs.dashboard
import qs.i18n
import qs.panels
import qs.services
import qs.theme

// Quick settings: do not disturb, microphone, Wi-Fi,
// Bluetooth, dark mode, screen recording (placeholder), as theme tiles
// (Toggle), plus volume and brightness sliders. Every size reaches every
// setting: what doesn't fit goes behind a "More" tile (last slot) that
// opens all of them in a panel over the screen. Tiles fill the cell:
//   tiny    one tile (More: everything in the panel)
//   narrow  one column
//   strip   one row, tiles of 220 px or more
//   wide    2 rows above 250 px
//   box     2 or 3 columns, rows of 120 px or more
//   tall    2 columns
// Sliders under the tiles when there is room (always in the panel).
// Big cells: the 8 tiles in 4 × 2, volume, brightness and microphone
// sliders; poster: the audio outputs and inputs listed on the right.
ModuleBase {
    id: root

    // In the panel: everything, sliders included.
    property bool full: false
    property bool panelOpen: false

    readonly property string look: theme.style.module ?? "classic"
    readonly property bool narrowLabels: tilesWidth / Math.max(1, cols) < (look === "matrix" || look === "facade" || look === "modulaire" ? 300 : 200)
    // The focused screen's brightness, else the first screen that has one.
    readonly property var brightness: {
        const focused = Brightness.forScreen(Hyprland.focusedMonitor?.name ?? "");
        return focused?.available ? focused : Brightness.monitors.find(m => m.available) ?? null;
    }

    // (panels/QuickToggles: shared with the bar's quick settings.)
    readonly property var tiles: QuickToggles.tiles.map(t => Object.assign({}, t, { label: narrowLabels && t.short ? t.short : t.label }))
    readonly property var more: ({ id: "more", icon: shape === "tiny" ? "tune" : "more_horiz", label: I18n.tr(shape === "tiny" ? "toggles.all" : "toggles.more"), sub: "", on: false })

    function activate(id: string): void {
        if (id === "more")
            panelOpen = true;
        else
            QuickToggles.activate(id);
    }

    // Fixed counts (the labels depend on the columns, which depend on them).
    readonly property int total: 8
    readonly property int levels: large ? 3 : 2
    // Poster: the audio devices' column.
    // Big cells: tiles on top (60 %, poster 50 %), then a
    // levels zone; poster: the audio outputs and inputs beside it (thirds).
    readonly property bool bigLayout: large && !full
    readonly property real zonesTop: bigLayout ? Math.round(ch * (poster ? 0.5 : 0.6)) + gap : 0
    readonly property real zoneWidth: poster ? (cw - 2 * gap) / 3 : cw
    readonly property real devicesWidth: 0
    // Strips, wide and narrow cells: compact rows (52 px, a comfortable
    // touch target), so even a one-unit-high cell holds two rows of buttons.
    readonly property bool compact: shape === "strip" || shape === "wide" || shape === "narrow"
    readonly property real compactRow: 52
    // (From the cell's height: compact shapes have no sliders under.)
    readonly property int rowsFit: Math.max(1, Math.floor((ch + gap) / (compactRow + gap)))
    readonly property int colsFit: Math.max(1, Math.floor((tilesWidth + gap) / ((look === "matrix" ? 120 : 140) + gap)))
    readonly property int cols: large && !full ? 4
        : shape === "tiny" || shape === "narrow" ? 1
        : compact ? Math.max(1, Math.min(colsFit, Math.ceil(total / rowsFit)))
        : shape === "tall" ? 2
        : cw / 3 >= 160 ? 3 : 2
    // Rows never under the touch target size (72 px on the modules screen).
    readonly property real minRow: Math.max(theme.hit, look === "matrix" ? 60 : shape === "narrow" ? 80 : 110)
    readonly property real sliderRow: large ? hit : Math.max(48, theme.hit * 0.75)
    readonly property real sliderBlock: levels * sliderRow + levels * gap
    // Wide cells: the sliders in a column on the right of the tiles.
    readonly property bool sideSliders: !full && !large && ((shape === "wide" && cw >= 780 && ch > 250) || (shape === "strip" && cw >= 900)) && ch >= sliderBlock - gap
    readonly property real sideWidth: Math.min(cw * 0.36, 420)
    readonly property real tilesWidth: sideSliders ? cw - sideWidth - gap * 1.5 : devicesWidth > 0 ? cw - devicesWidth - gap * 1.5 : cw
    // Sliders under the tiles: always in the panel; in the cell when the
    // tiles still get their minimum rows above them.
    readonly property bool sliders: sideSliders || full || large || ((shape === "box" || shape === "tall") && ch - sliderBlock >= Math.ceil(total / cols) * (minRow + gap) - gap)
    // In the panel: rows of a fixed height, the sliders right under them.
    readonly property real fullRow: Math.max(64, theme.hit)
    readonly property real tilesHeight: full ? Math.ceil(total / cols) * (fullRow + gap) - gap
        : bigLayout ? zonesTop - gap
        : sliders && !sideSliders ? ch - sliderBlock : ch
    readonly property int rows: shape === "tiny" ? 1
        : full ? Math.ceil(total / cols)
        : compact ? Math.max(1, Math.min(rowsFit, Math.ceil(total / cols)))
        : Math.max(1, Math.min(Math.ceil(total / cols), Math.floor((tilesHeight + gap) / (minRow + gap))))
    readonly property int capacity: shape === "tiny" ? 1 : cols * rows
    // Everything in view, or the first tiles and More in the last slot.
    readonly property bool complete: full || (capacity >= total && sliders)
    readonly property var shown: complete ? tiles : [...tiles.slice(0, Math.max(0, Math.min(total, capacity) - 1)), more]

    Grid {
        id: grid

        readonly property int lines: Math.ceil(root.shown.length / columns)
        readonly property real cellW: (width - (columns - 1) * spacing) / columns
        readonly property real cellH: (height - (lines - 1) * spacing) / lines

        width: root.tilesWidth
        height: root.tilesHeight
        columns: Math.min(root.cols, root.shown.length)
        spacing: root.gap

        Repeater {
            model: root.shown

            Toggle {
                required property var modelData

                width: grid.cellW
                height: grid.cellH
                opacity: modelData.placeholder ? 0.45 : 1
                plain: modelData.id === "more" || !!modelData.placeholder
                icon: modelData.icon
                label: modelData.label
                sub: modelData.sub
                on: modelData.on
                onTapped: root.activate(modelData.id)
            }
        }
    }

    // Volume (the icon mutes) and brightness, under the tiles.
    Column {
        visible: root.sliders
        x: root.sideSliders ? parent.width - width : root.bigLayout ? levelsZone.body.x : 0
        y: root.sideSliders ? (parent.height - height) / 2 : root.full ? root.tilesHeight + root.gap * 1.5 : root.bigLayout ? levelsZone.y + levelsZone.body.y + (levelsZone.body.height - height) / 2 : parent.height - height
        width: root.sideSliders ? root.sideWidth : root.bigLayout ? levelsZone.body.width : root.tilesWidth
        z: 1
        spacing: root.gap

        Repeater {
            model: [
                { icon: Audio.muted ? "volume_off" : "volume_up", value: Audio.volume, to: Audio.maxVolume, kind: "volume", text: Audio.muted ? I18n.tr("common.muted") : I18n.percent(Audio.volume), enabled: true },
                { icon: "light_mode", value: root.brightness?.brightness ?? 0, to: 1, kind: "brightness", text: root.brightness ? I18n.percent(root.brightness.brightness) : "—", enabled: !!root.brightness },
                ...(root.large ? [{ icon: Audio.sourceMuted ? "mic_off" : "mic", value: Audio.sourceVolume, to: 1, kind: "mic", text: Audio.sourceMuted ? I18n.tr("common.muted") : I18n.percent(Audio.sourceVolume), enabled: !!Audio.source }] : [])
            ]

            Item {
                id: level

                required property var modelData

                width: parent.width
                height: root.sliderRow
                opacity: modelData.enabled ? 1 : 0.45

                Icon {
                    id: levelIcon
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.sliderRow
                    name: level.modelData.icon
                    size: Math.max(22, Math.min(32, root.sliderRow * 0.55))
                    color: root.theme.color.soft

                    MouseArea {
                        anchors.fill: parent
                        enabled: level.modelData.kind === "volume" || level.modelData.kind === "mic"
                        cursorShape: Qt.PointingHandCursor
                        onClicked: level.modelData.kind === "mic" ? Audio.toggleSourceMute() : Audio.toggleMute()
                    }
                }

                Slider {
                    anchors.left: levelIcon.right
                    anchors.right: levelValue.left
                    anchors.rightMargin: root.gap
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: level.modelData.enabled
                    value: level.modelData.value
                    to: level.modelData.to
                    dimmed: level.modelData.kind === "volume" && Audio.muted || level.modelData.kind === "mic" && Audio.sourceMuted
                    onMoved: value => level.modelData.kind === "volume" ? Audio.setVolume(value) : level.modelData.kind === "mic" ? Audio.setSourceVolume(value) : root.brightness?.setBrightness(value)
                }

                ThemedText {
                    id: levelValue
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.t3 * 3.4
                    horizontalAlignment: Text.AlignRight
                    text: level.modelData.text
                    font.pixelSize: root.t3
                    font.features: ({ "tnum": 1 })
                    color: root.theme.color.ink
                }
            }
        }
    }

    // Big cells: the levels' zone (the sliders sit over it).
    ModuleZone {
        id: levelsZone
        visible: root.bigLayout
        y: root.zonesTop
        width: root.zoneWidth
        height: root.ch - y
        label: I18n.tr("toggles.levels")
        labelSize: root.t4
        gap: root.gap
    }

    // Poster: audio outputs and inputs, the default one checked.
    Row {
        visible: root.bigLayout && root.poster
        x: root.zoneWidth + root.gap
        y: root.zonesTop
        width: root.cw - x
        height: root.ch - y
        spacing: root.gap

        Repeater {
            model: [
                { label: I18n.tr("toggles.outputs"), nodes: Audio.sinks, current: Audio.sink, output: true },
                { label: I18n.tr("toggles.inputs"), nodes: Audio.sources, current: Audio.source, output: false }
            ]

            ModuleZone {
                id: devZone
                required property var modelData
                width: root.zoneWidth
                height: parent.height
                label: modelData.label
                labelSize: root.t4
                gap: root.gap

                Column {
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: devZone.modelData.nodes.slice(0, Math.max(1, Math.floor(devZone.body.height / (root.t3 * 2.2))))

                        Item {
                            id: devRow
                            required property var modelData
                            readonly property bool current: modelData === devZone.modelData.current
                            width: parent.width
                            height: root.t3 * 2.2

                            Rectangle {
                                anchors.fill: parent
                                radius: root.theme.radius.tile
                                color: devArea.containsMouse ? Qt.alpha(root.theme.color.ink, 0.06) : "transparent"
                            }

                            Icon {
                                id: devCheck
                                anchors.verticalCenter: parent.verticalCenter
                                x: 6
                                name: devRow.current ? "radio_button_checked" : "radio_button_unchecked"
                                size: root.t3 * 1.1
                                color: devRow.current ? (root.look === "matrix" ? root.theme.color.ink : root.theme.color.accent) : root.theme.color.soft
                            }

                            ThemedText {
                                anchors.verticalCenter: parent.verticalCenter
                                x: devCheck.x + devCheck.width + root.gap * 0.5
                                width: parent.width - x - 6
                                elide: Text.ElideRight
                                text: Audio.nodeName(devRow.modelData)
                                font.family: devZone.textFont
                                font.pixelSize: root.t3
                                color: devRow.current ? devZone.ink : devZone.soft
                            }

                            MouseArea {
                                id: devArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: devZone.modelData.output ? Audio.setDefaultSink(devRow.modelData) : Audio.setDefaultSource(devRow.modelData)
                            }
                        }
                    }
                }
            }
        }
    }

    // Reviews: the panel without a click.
    Connections {
        target: Showcase

        function onTogglesPanelChanged(): void {
            if (!root.full)
                root.panelOpen = Showcase.togglesPanel;
        }
    }

    // Everything, in a panel over the screen (More tile), sized to its
    // content. Hidden rather than destroyed on close, the grab off first:
    // the keyboard goes back to the window it came from.
    property bool panelLoaded: false
    onPanelOpenChanged: {
        if (panelOpen)
            panelLoaded = true;
        else
            Qt.callLater(ShellState.restoreFocus);
    }
    readonly property real panelHit: Math.max(64, theme.hit)

    LazyLoader {
        active: root.panelLoaded && !root.full

        PanelWindow {
            id: panel

            readonly property var theme: root.theme

            visible: root.panelOpen
            screen: root.QsWindow.window?.screen ?? null
            implicitWidth: Math.min((screen?.width ?? 1200) - 80, 760)
            // Title, 3 rows of 3 tiles, the two sliders, paddings.
            implicitHeight: Math.min((screen?.height ?? 700) - 40, 40 + 48 + 3 * root.panelHit + 2 * 14 + 21 + 2 * (Math.max(48, root.theme.hit * 0.75) + 14))
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "lc-quicksettings"
            WlrLayershell.keyboardFocus: panel.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            HyprlandFocusGrab {
                active: panel.visible && !Showcase.togglesPanel
                windows: [panel]
                onCleared: root.panelOpen = false
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.panelOpen = false

                // By url: a type can't name itself.
                Loader {
                    anchors.fill: parent
                    Component.onCompleted: setSource(Qt.resolvedUrl("Toggles.qml"), { full: true, options: { type: "toggles" } })
                }

                WindowBorder {
                    radius: root.look === "matrix" ? 28 : root.theme.radius.card
                }

                ModuleButton {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    icon: "close"
                    size: 44
                    onTapped: root.panelOpen = false
                }
            }
        }
    }
}
