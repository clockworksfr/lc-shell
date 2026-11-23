import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// The bar's quick settings (screens without the modules dashboard): the
// switches as tiles, volume and brightness, then network and Bluetooth,
// each opening its own page (back arrow on top).
Column {
    id: root

    readonly property var theme: QsWindow.window?.theme ?? Themes.fallback
    readonly property string screenName: QsWindow.window?.bar?.screen?.name ?? ""

    // "main" | "network" | "bluetooth"
    property string page: "main"
    onPageChanged: {
        if (page === "bluetooth")
            BluetoothService.discoveryRequests += 1;
        else if (scanning)
            BluetoothService.discoveryRequests -= 1;
        scanning = page === "bluetooth";
    }
    property bool scanning: false
    Component.onDestruction: if (scanning) BluetoothService.discoveryRequests -= 1

    // Back to the tiles when the drawer closes.
    Connections {
        target: root.QsWindow.window
        function onVisibleChanged(): void {
            if (!root.QsWindow.window?.visible)
                root.page = "main";
        }
    }

    readonly property var brightness: {
        const own = Brightness.forScreen(screenName);
        return own?.available ? own : Brightness.monitors.find(m => m.available) ?? null;
    }
    readonly property real gap: theme.space.s

    width: 440
    spacing: theme.space.m

    // --- Main page ---

    Grid {
        id: grid

        visible: root.page === "main"
        width: parent.width
        columns: 3
        spacing: root.gap

        Repeater {
            model: QuickToggles.tiles

            Toggle {
                required property var modelData

                width: (grid.width - 2 * grid.spacing) / 3
                height: 60
                opacity: modelData.placeholder ? 0.5 : 1
                plain: !!modelData.placeholder
                icon: modelData.icon
                label: modelData.short || modelData.label
                sub: modelData.sub
                on: modelData.on
                onTapped: {
                    const id = modelData.id;
                    Qt.callLater(() => QuickToggles.activate(id));
                }
            }
        }
    }

    Repeater {
        model: root.page === "main" ? [
            { icon: Audio.muted ? "volume_off" : "volume_up", value: Audio.volume, to: Audio.maxVolume, kind: "volume", text: Audio.muted ? I18n.tr("common.muted") : I18n.percent(Audio.volume), enabled: true },
            { icon: "light_mode", value: root.brightness?.brightness ?? 0, to: 1, kind: "brightness", text: root.brightness ? I18n.percent(root.brightness.brightness) : "—", enabled: !!root.brightness }
        ] : []

        Item {
            id: level

            required property var modelData

            width: root.width
            height: Math.max(36, root.theme.hit * 0.8)
            opacity: modelData.enabled ? 1 : 0.45

            Icon {
                id: levelIcon
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                name: level.modelData.icon
                size: 22
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
                anchors.leftMargin: root.gap
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
                width: 52
                horizontalAlignment: Text.AlignRight
                text: level.modelData.text
                font.features: ({ "tnum": 1 })
            }
        }
    }

    ListRow {
        visible: root.page === "main"
        title: I18n.tr("net.title")
        subtitle: [NetworkService.kind === "wired" ? I18n.tr("net.wired") : NetworkService.kind === "wifi" ? NetworkService.activeWifi.name : I18n.tr("net.offline"), VpnService.active || VpnService.activeNames.length > 0 ? "VPN" : ""].filter(s => !!s).join(" · ")
        trailing: "›"
        onClicked: root.page = "network"
    }

    ListRow {
        visible: root.page === "main" && BluetoothService.available
        title: I18n.tr("bt.title")
        subtitle: !BluetoothService.enabled ? I18n.tr("qs.off") : BluetoothService.connected.map(d => d.name).join(", ") || I18n.tr("qs.noDevice")
        trailing: "›"
        onClicked: root.page = "bluetooth"
    }

    // --- Network and Bluetooth pages ---

    ListRow {
        visible: root.page !== "main"
        title: `‹  ${I18n.tr(root.page === "network" ? "net.title" : "bt.title")}`
        onClicked: root.page = "main"
    }

    Loader {
        active: root.page === "network"
        visible: active
        width: root.width
        sourceComponent: NetworkPanel {
            width: root.width
        }
    }

    Loader {
        active: root.page === "bluetooth"
        visible: active
        width: root.width
        sourceComponent: BluetoothPanel {
            width: root.width
        }
    }
}
