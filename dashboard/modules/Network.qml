import QtQuick
import Quickshell
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Download and upload rates with their last minute, for the active
// interface, one picked by hand, or all of them added up (the chip in the
// title row, or a right click: same menu as the media source). By shape:
//   tiny    download big, upload under
//   narrow  download, then upload, each with its curve
//   wide / strip  the two side by side (figure over the curve)
//   box / tall    the two stacked
// Big cells: big figure, average and peak of the minute, a tall curve with
// its time axis (large: stacked; poster: side by side, and a connection
// row — wired, Wi-Fi on / off (no name), VPN, Internet).
ModuleBase {
    id: root

    readonly property string look: theme.style.module ?? "classic"
    readonly property bool stacked: poster ? false : large || shape === "narrow" || shape === "box" || shape === "tall"
    readonly property real connectionHeight: poster ? t3 * 2.6 : 0

    Component.onCompleted: NetworkService.watchers++
    Component.onDestruction: NetworkService.watchers--

    function sourceLabel(): string {
        const s = NetworkService.source;
        return s === "auto" ? `${NetworkService.iface || "—"} · ${I18n.tr("media.source.autoShort")}` : s === "all" ? I18n.tr("network.all") : s;
    }

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
            { id: "auto", text: I18n.tr("network.auto"), check: "radio", checked: NetworkService.source === "auto" },
            { id: "all", text: I18n.tr("network.allLong"), check: "radio", checked: NetworkService.source === "all" },
            ...NetworkService.interfaces.map(i => ({ id: i.name, text: `${i.name} · ${I18n.tr(i.wifi ? "network.wifi" : "network.wired")}`, check: "radio", checked: NetworkService.source === i.name }))
        ]
        onPicked: id => NetworkService.setSource(id)
    }

    titleReserve: chip.visible ? chip.width + 14 : 0

    // The chip in the title row.
    Item {
        id: chip

        parent: root
        // Beside the title only when there's room for both.
        visible: root.inner.y > root.pad + 1 && root.width >= width + 150
        // A small pill on the title row (design review): surface fill,
        // line border, 12 px ink text with its "⌄".
        x: root.width - width - 14
        y: 8
        width: chipRow.implicitWidth + 20
        height: 22

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: chipArea.containsMouse || chipArea.pressed ? root.theme.color.surface3 : root.theme.color.surface
            border.width: 1
            border.color: root.theme.color.line
        }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                label: true
                text: `${root.sourceLabel()} ⌄`
                font.pixelSize: 12
                font.letterSpacing: 0.5
                color: root.theme.color.ink
            }
        }

        MouseArea {
            id: chipArea
            anchors.fill: parent
            anchors.margins: -12
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.openSources(chip)
        }
    }

    ThemedText {
        anchors.centerIn: parent
        visible: NetworkService.sourceNames.length === 0
        text: I18n.tr("net.offline")
        font.pixelSize: root.t3
        color: root.theme.color.soft
    }

    // One direction: label, rate, curve.
    component Lane: Item {
        id: lane

        property var m
        property string glyph
        property string label
        property real rate
        property var history: []
        property color lineColor
        property bool showCurve: height >= lane.m.t2 * 2.6

        readonly property string text: I18n.bytes(rate, true)
        // Facade / modulaire: both lanes in one screen of the theme (VFD,
        // green LCD), drawn by the module.
        readonly property bool onScreen: lane.m.look === "facade" || lane.m.look === "modulaire"
        readonly property var laneScreen: lane.m.sharedScreen
        readonly property color ink: onScreen ? laneScreen.ink : lane.m.theme.color.ink
        readonly property color soft: onScreen ? laneScreen.soft : lane.m.theme.color.soft
        // Figure size per shape (design review).
        readonly property real figurePx: lane.big ? Math.min(lane.m.heroMax * 0.6, lane.height * 0.3)
            : lane.m.shape === "box" || lane.m.shape === "tall" ? Math.min(lane.m.ch, lane.m.cw) * 0.12
            : lane.m.shape === "wide" || lane.m.shape === "strip" ? Math.min(lane.m.ch * 0.2, lane.m.cw * 0.06)
            : Math.min(lane.m.t2 * 1.5, lane.height * (lane.showCurve ? 0.32 : 0.55))
        // "12,4 Mo/s" → figure "12,4", unit "Mo/s".
        readonly property var parts: /^([\d\s.,]+)\s*(.*)$/.exec(text) ?? [text, text, ""]
        readonly property bool big: lane.m.large
        readonly property real axisHeight: big ? lane.m.t4 * 1.6 : 0

        Column {
            id: head
            width: parent.width
            spacing: 2

            ThemedText {
                label: true
                text: `${lane.glyph} ${lane.label}`
                font.family: lane.onScreen ? lane.laneScreen.textFont : lane.m.theme.font.family
                font.pixelSize: lane.m.t4
                color: lane.soft
            }

            Row {
                spacing: 6

                Figure {
                    id: laneFigure
                    text: lane.parts[1].trim()
                    // Matrix: the dots glow.
                    glow: false
                    color: lane.onScreen ? lane.ink : lane.m.theme.color.nixie ?? lane.m.theme.color.ink
                    pixelSize: Math.max(14, lane.figurePx)
                }

                ThemedText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    text: lane.parts[2]
                    font.pixelSize: Math.max(11, lane.figurePx * 0.4)
                    color: lane.soft
                }
            }

            // Big cells: the minute's average and peak.
            ThemedText {
                visible: lane.big
                text: I18n.tr("system.avgPeak", { avg: I18n.bytes(lane.history.length ? lane.history.reduce((a, b) => a + b, 0) / lane.history.length : 0, true), peak: I18n.bytes(Math.max(0, ...lane.history), true) })
                font.family: lane.onScreen ? lane.laneScreen.textFont : lane.m.theme.font.family
                font.pixelSize: lane.m.t4 * 1.1
                font.features: ({ "tnum": 1 })
                color: lane.soft
            }
        }

        Sparkline {
            visible: lane.showCurve
            anchors.top: head.bottom
            anchors.topMargin: lane.m.gap / 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: lane.axisHeight
            width: parent.width
            values: lane.history
            lineWidth: 1.4
            fillAlpha: 0.18
            // Its own scale (upload would flatten under download).
            max: Math.max(16 * 1024, ...lane.history)
            color: lane.onScreen ? lane.ink : lane.lineColor
        }

        // Big cells: the time axis under the curve.
        Item {
            visible: lane.big
            anchors.bottom: parent.bottom
            width: parent.width
            height: lane.axisHeight

            Repeater {
                model: ["−60 s", "−30 s", I18n.tr("network.now")]

                ThemedText {
                    required property string modelData
                    required property int index
                    x: index === 0 ? 0 : index === 1 ? (parent.width - width) / 2 : parent.width - width
                    anchors.bottom: parent.bottom
                    label: true
                    text: modelData
                    font.family: lane.onScreen ? lane.laneScreen.textFont : lane.m.theme.font.mono
                    font.pixelSize: lane.m.t4
                    color: lane.soft
                }
            }
        }
    }

    // tiny: the two figures.
    Column {
        visible: !root.large && root.shape === "tiny" && NetworkService.sourceNames.length > 0
        anchors.centerIn: parent
        spacing: 2

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `↓ ${I18n.bytes(NetworkService.rxRate, true)}`
            font.pixelSize: root.t2
            font.weight: Font.DemiBold
            font.features: ({ "tnum": 1 })
        }

        ThemedText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: `↑ ${I18n.bytes(NetworkService.txRate, true)}`
            font.pixelSize: root.t3
            font.features: ({ "tnum": 1 })
            color: root.theme.color.soft
        }
    }

    // Facade / modulaire: one screen for both lanes (VFD; modulaire a
    // green LCD).
    property var sharedScreen: sharedDisplay
    Display {
        id: sharedDisplay
        visible: (root.look === "facade" || root.look === "modulaire") && NetworkService.sourceNames.length > 0 && (root.large || root.shape !== "tiny")
        anchors.fill: parent
        anchors.margins: -6
        anchors.bottomMargin: root.poster ? root.connectionHeight + root.gap * 1.5 - 6 : -6
        tint: "green"
    }

    // The two lanes, side by side or stacked.
    Grid {
        visible: (root.large || root.shape !== "tiny") && NetworkService.sourceNames.length > 0
        anchors.fill: parent
        anchors.bottomMargin: root.poster ? root.connectionHeight + root.gap * 1.5 : 0
        columns: root.stacked ? 1 : 2
        spacing: root.gap * 1.5

        Repeater {
            model: [
                { glyph: "↓", label: I18n.tr("card.download"), rx: true },
                { glyph: "↑", label: I18n.tr("card.upload"), rx: false }
            ]

            Lane {
                required property var modelData
                m: root
                width: root.stacked ? root.cw : (root.cw - root.gap * 1.5) / 2
                height: (root.stacked ? (root.ch - root.gap * 1.5) / 2 : root.ch) - (root.poster ? root.connectionHeight + root.gap * 1.5 : 0)
                glyph: modelData.glyph
                label: modelData.label
                rate: modelData.rx ? NetworkService.rxRate : NetworkService.txRate
                history: modelData.rx ? NetworkService.rxHistory : NetworkService.txHistory
                // Upload: the second accent, or a cool blue where the theme
                // has a single one (Classic).
                lineColor: modelData.rx ? root.theme.color.accent : (root.theme.color.accent2 && Qt.colorEqual(root.theme.color.accent2, root.theme.color.accent) === false ? root.theme.color.accent2 : "#5AA0C8")
            }
        }
    }

    // Poster: the connection, in pills (no network names).
    Row {
        visible: root.poster
        anchors.bottom: parent.bottom
        width: parent.width
        height: root.connectionHeight
        spacing: root.gap

        Repeater {
            id: pills
            model: [
                { icon: "lan", label: I18n.tr("network.wired"), on: NetworkService.wiredConnected },
                { icon: NetworkService.wifiEnabled ? "wifi" : "wifi_off", label: I18n.tr("network.wifi"), on: NetworkService.wifiEnabled && !!NetworkService.activeWifi },
                ...(VpnService.available ? [{ icon: "vpn_key", label: "VPN", on: VpnService.active }] : []),
                { icon: "public", label: I18n.tr("network.internet"), on: NetworkService.online }
            ]

            Rectangle {
                required property var modelData
                width: (parent.width - (pills.count - 1) * parent.spacing) / Math.max(1, pills.count)
                height: parent.height
                radius: root.look === "matrix" || root.look === "classic" || root.look === "constellation" ? height / 2 : 4
                // Matrix: ink (its red is for alerts only).
                readonly property color tone: root.look === "matrix" ? root.theme.color.ink : (root.theme.color.signal ?? root.theme.color.accent)
                color: modelData.on && root.look !== "matrix" ? Qt.alpha(tone, 0.14) : "transparent"
                border.width: 1
                border.color: modelData.on ? tone : root.theme.color.line

                Row {
                    anchors.centerIn: parent
                    spacing: root.gap * 0.5

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: parent.parent.modelData.icon
                        size: root.t3 * 1.2
                        color: parent.parent.modelData.on ? root.theme.color.ink : root.theme.color.soft
                    }

                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.parent.modelData.label
                        font.pixelSize: root.t3
                        color: parent.parent.modelData.on ? root.theme.color.ink : root.theme.color.soft
                    }
                }
            }
        }
    }
}
