import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.components.dashboard
import qs.dashboard
import qs.lock
import qs.i18n
import qs.services
import qs.theme

// Quick settings (design study 9): do not disturb, microphone, Wi-Fi,
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

    readonly property var tiles: [
        {
            id: "dnd",
            icon: "do_not_disturb_on",
            label: I18n.tr(narrowLabels ? "toggles.dndShort" : "toggles.dnd"),
            sub: NotificationCenter.dnd ? I18n.tr("toggles.on") : "",
            on: NotificationCenter.dnd
        },
        {
            id: "mic",
            icon: Audio.sourceMuted ? "mic_off" : "mic",
            label: I18n.tr("toggles.mic"),
            sub: Audio.sourceMuted ? I18n.tr("common.muted") : I18n.percent(Audio.sourceVolume),
            on: !Audio.sourceMuted
        },
        {
            id: "wifi",
            icon: NetworkService.wifiEnabled ? "wifi" : "wifi_off",
            label: I18n.tr("toggles.wifi"),
            sub: NetworkService.activeWifi?.name ?? "",
            on: NetworkService.wifiEnabled
        },
        {
            id: "bluetooth",
            icon: BluetoothService.enabled ? "bluetooth" : "bluetooth_disabled",
            label: I18n.tr("toggles.bluetooth"),
            sub: BluetoothService.devices.filter(d => d.connected).map(d => d.name).join(", "),
            on: BluetoothService.enabled
        },
        {
            id: "dark",
            icon: "dark_mode",
            label: I18n.tr("toggles.dark"),
            sub: Themes.variantMode === "auto" ? I18n.tr("toggles.auto") : "",
            on: Themes.variant === "dark"
        },
        {
            id: "caffeine",
            icon: "coffee",
            label: I18n.tr("toggles.caffeine"),
            sub: Idle.caffeine ? I18n.tr("toggles.awake") : "",
            on: Idle.caffeine
        },
        {
            id: "record",
            icon: "screen_record",
            label: I18n.tr("toggles.record"),
            sub: I18n.tr("toggles.soon"),
            on: false,
            placeholder: true
        }
    ]
    readonly property var more: ({ id: "more", icon: shape === "tiny" ? "tune" : "more_horiz", label: I18n.tr(shape === "tiny" ? "toggles.all" : "toggles.more"), sub: "", on: false })

    function activate(id: string): void {
        switch (id) {
        case "dnd":
            NotificationCenter.setDnd(!NotificationCenter.dnd);
            break;
        case "mic":
            Audio.toggleSourceMute();
            break;
        case "wifi":
            NetworkService.setWifiEnabled(!NetworkService.wifiEnabled);
            break;
        case "bluetooth":
            BluetoothService.setEnabled(!BluetoothService.enabled);
            break;
        case "dark":
            Themes.toggleVariant();
            break;
        case "caffeine":
            Idle.caffeine = !Idle.caffeine;
            break;
        case "more":
            panelOpen = true;
            break;
        }
    }

    // Fixed counts (the labels depend on the columns, which depend on them).
    readonly property int total: 7
    readonly property int levels: 2
    // Strips, wide and narrow cells: compact rows (52 px, a comfortable
    // touch target), so even a one-unit-high cell holds two rows of buttons.
    readonly property bool compact: shape === "strip" || shape === "wide" || shape === "narrow"
    readonly property real compactRow: 52
    readonly property int rowsFit: Math.max(1, Math.floor((tilesHeight + gap) / (compactRow + gap)))
    readonly property int colsFit: Math.max(1, Math.floor((tilesWidth + gap) / ((look === "matrix" ? 120 : 140) + gap)))
    readonly property int cols: shape === "tiny" || shape === "narrow" ? 1
        : compact ? Math.max(1, Math.min(colsFit, Math.ceil(total / rowsFit)))
        : shape === "tall" ? 2
        : cw / 3 >= 160 ? 3 : 2
    // Rows never under the touch target size (72 px on the modules screen).
    readonly property real minRow: Math.max(theme.hit, look === "matrix" ? 60 : shape === "narrow" ? 80 : 110)
    readonly property real sliderRow: Math.max(48, theme.hit * 0.75)
    readonly property real sliderBlock: levels * sliderRow + levels * gap
    // Wide cells: the sliders in a column on the right of the tiles.
    readonly property bool sideSliders: !full && ((shape === "wide" && cw >= 620) || (shape === "strip" && cw >= 900)) && ch >= sliderBlock - gap
    readonly property real sideWidth: Math.min(cw * 0.36, 420)
    readonly property real tilesWidth: sideSliders ? cw - sideWidth - gap * 1.5 : cw
    // Sliders under the tiles: always in the panel; in the cell when the
    // tiles still get their minimum rows above them.
    readonly property bool sliders: sideSliders || full || ((shape === "box" || shape === "tall") && ch - sliderBlock >= Math.ceil(total / cols) * (minRow + gap) - gap)
    // In the panel: rows of a fixed height, the sliders right under them.
    readonly property real fullRow: Math.max(64, theme.hit)
    readonly property real tilesHeight: full ? Math.ceil(total / cols) * (fullRow + gap) - gap
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
                opacity: modelData.placeholder ? 0.5 : 1
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
        x: root.sideSliders ? parent.width - width : 0
        y: root.sideSliders ? (parent.height - height) / 2 : root.full ? root.tilesHeight + root.gap * 1.5 : parent.height - height
        width: root.sideSliders ? root.sideWidth : parent.width
        spacing: root.gap

        Repeater {
            model: [
                { icon: Audio.muted ? "volume_off" : "volume_up", value: Audio.volume, to: Audio.maxVolume, kind: "volume", text: Audio.muted ? I18n.tr("common.muted") : I18n.percent(Audio.volume), enabled: true },
                { icon: "light_mode", value: root.brightness?.brightness ?? 0, to: 1, kind: "brightness", text: root.brightness ? I18n.percent(root.brightness.brightness) : "—", enabled: !!root.brightness }
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
                        enabled: level.modelData.kind === "volume"
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.toggleMute()
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
                    dimmed: level.modelData.kind === "volume" && Audio.muted
                    onMoved: value => level.modelData.kind === "volume" ? Audio.setVolume(value) : root.brightness?.setBrightness(value)
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
