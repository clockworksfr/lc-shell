import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Quick settings (design study 9): do not disturb, microphone, Wi-Fi,
// Bluetooth, dark mode, as theme tiles (Toggle) filling the cell:
//   tiny    the first tile
//   narrow  one column
//   strip   one row, up to 6 tiles of 220 px or more
//   wide    2 rows above 250 px
//   box     2 or 3 columns, rows of 120 px or more
//   tall    2 columns
// Room left under the grid (box, tall): volume and brightness sliders.
ModuleBase {
    id: root

    readonly property bool narrowLabels: cw / Math.max(1, cols) < (look === "matrix" || look === "facade" || look === "modulaire" ? 300 : 200)
    readonly property string look: theme.style.module ?? "classic"
    readonly property var brightness: Brightness.forScreen(Hyprland.focusedMonitor?.name ?? "")

    readonly property var toggles: [
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
        }
    ]

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
        }
    }

    // Fixed count (the labels depend on the columns, which depend on it).
    readonly property int total: 5
    readonly property int cols: shape === "tiny" || shape === "narrow" ? 1
        : shape === "strip" ? Math.max(1, Math.min(total, 6, Math.floor((cw + gap) / (220 + gap))))
        : shape === "wide" ? Math.ceil(total / (ch > 250 ? 2 : 1))
        : shape === "tall" ? 2
        : cw / 3 >= 160 ? 3 : 2
    readonly property real minRow: look === "matrix" ? 56 : shape === "narrow" ? 72 : 120
    readonly property int rows: shape === "tiny" || shape === "strip" ? 1
        : shape === "wide" ? (ch > 250 ? 2 : 1)
        : Math.max(1, Math.min(Math.ceil(total / cols), Math.floor((ch + gap) / (minRow + gap))))
    readonly property int count: shape === "tiny" ? 1 : Math.min(total, cols * rows)
    // Sliders under the grid when the cell is tall enough (box, tall).
    readonly property bool sliders: (shape === "box" || shape === "tall") && ch - gridHeight >= 110
    readonly property real gridHeight: (shape === "box" || shape === "tall") ? Math.min(ch, Math.ceil(count / cols) * (look === "matrix" ? 80 : 150) + (Math.ceil(count / cols) - 1) * gap) : ch

    Grid {
        id: grid

        readonly property real cellW: (width - (columns - 1) * spacing) / columns
        readonly property real cellH: (height - (Math.ceil(root.count / columns) - 1) * spacing) / Math.ceil(root.count / columns)

        width: parent.width
        height: root.sliders ? root.gridHeight : parent.height
        columns: root.cols
        spacing: root.gap

        Repeater {
            model: root.toggles.slice(0, root.count)

            Toggle {
                required property var modelData

                width: grid.cellW
                height: grid.cellH
                icon: modelData.icon
                label: modelData.label
                sub: modelData.sub
                on: modelData.on
                onTapped: root.activate(modelData.id)
            }
        }
    }

    // Volume and brightness, under the grid.
    Column {
        visible: root.sliders
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: grid.bottom
        anchors.topMargin: root.gap
        spacing: root.gap

        Repeater {
            model: [
                { icon: Audio.muted ? "volume_off" : "volume_up", value: Audio.volume, to: Audio.maxVolume, kind: "volume" },
                ...(root.brightness?.available ? [{ icon: "light_mode", value: root.brightness.brightness, to: 1, kind: "brightness" }] : [])
            ]

            Row {
                required property var modelData

                width: parent.width
                spacing: root.gap

                Icon {
                    id: sliderIcon
                    anchors.verticalCenter: parent.verticalCenter
                    name: parent.modelData.icon
                    size: Math.max(22, root.t2)
                    color: root.theme.color.soft
                }

                Slider {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - sliderIcon.width - parent.spacing
                    value: parent.modelData.value
                    to: parent.modelData.to
                    onMoved: value => parent.modelData.kind === "volume" ? Audio.setVolume(value) : root.brightness.setBrightness(value)
                }
            }
        }
    }
}
