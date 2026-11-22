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
ModuleBase {
    id: root

    readonly property string look: theme.style.module ?? "classic"
    readonly property bool stacked: shape === "narrow" || shape === "box" || shape === "tall"

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

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                label: true
                text: root.sourceLabel()
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
        // Facade / modulaire: the lane in the theme's screen (VFD, amber LCD).
        readonly property bool onScreen: lane.m.look === "facade" || lane.m.look === "modulaire"
        readonly property color ink: onScreen ? screen.ink : lane.m.theme.color.ink
        readonly property color soft: onScreen ? screen.soft : lane.m.theme.color.soft

        Display {
            id: screen
            visible: lane.onScreen
            anchors.fill: parent
            anchors.margins: -6
            tint: "amber"
        }
        // "12,4 Mo/s" → figure "12,4", unit "Mo/s".
        readonly property var parts: /^([\d\s.,]+)\s*(.*)$/.exec(text) ?? [text, text, ""]

        Column {
            id: head
            width: parent.width
            spacing: 2

            ThemedText {
                label: true
                text: `${lane.glyph} ${lane.label}`
                font.family: lane.onScreen ? screen.textFont : lane.m.theme.font.family
                font.pixelSize: lane.m.t4
                color: lane.soft
            }

            Row {
                spacing: 6

                Figure {
                    text: lane.parts[1].trim()
                    glow: false
                    color: lane.onScreen ? lane.ink : lane.m.theme.color.nixie ?? lane.m.theme.color.ink
                    pixelSize: Math.min(lane.m.t2 * 1.5, lane.height * (lane.showCurve ? 0.32 : 0.55))
                }

                ThemedText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    text: lane.parts[2]
                    font.pixelSize: lane.m.t3
                    color: lane.soft
                }
            }
        }

        Sparkline {
            visible: lane.showCurve
            anchors.top: head.bottom
            anchors.topMargin: lane.m.gap / 2
            anchors.bottom: parent.bottom
            width: parent.width
            values: lane.history
            // Its own scale (upload would flatten under download).
            max: Math.max(16 * 1024, ...lane.history)
            color: lane.onScreen ? lane.ink : lane.lineColor
        }
    }

    // tiny: the two figures.
    Column {
        visible: root.shape === "tiny" && NetworkService.sourceNames.length > 0
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

    // The two lanes, side by side or stacked.
    Grid {
        visible: root.shape !== "tiny" && NetworkService.sourceNames.length > 0
        anchors.fill: parent
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
                height: root.stacked ? (root.ch - root.gap * 1.5) / 2 : root.ch
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
}
