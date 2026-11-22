import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.components.dashboard
import qs.i18n
import qs.services
import qs.theme

// Philips Hue lights (design-hue): A rooms (theme tiles), B the selected
// room (brightness, color, scenes), C its lights. By shape:
//   tiny    one "Lights" tile: opens the panel
//   narrow  A in a column, More last
//   strip   A in a row (and wide cells under 200 px), More last
//   box     small (< 480 × 400): A in 2 columns, More last;
//           else A on top, B under
//   tall    A as a list, B under
//   wide    A left, B right (≥ 200 px high); A, B, C side by side when
//           ≥ 1000 × 400 (and in the panel, `full`)
// More (and the last scene slot when scenes overflow) opens everything in
// a panel over the screen; the color swatch opens the color panel.
ModuleBase {
    id: root

    property bool full: false
    // Drawer of the bar (pointer sizes): everything, no More.
    property bool drawer: false
    property string selectedId: ""

    readonly property string look: theme.style.module ?? "classic"
    readonly property real hit: Math.max(36, theme.hit)
    readonly property var selected: HueBridge.room(selectedId) ?? HueBridge.rooms.find(r => r.on) ?? HueBridge.rooms[0] ?? null
    readonly property string mode: !HueBridge.loaded ? "state"
        : full || drawer || (shape === "wide" && ch >= 400 && cw >= 1000) ? "three"
        : shape === "tiny" ? "tiny"
        : shape === "narrow" ? "list"
        : (shape === "strip" || shape === "wide") && ch < 200 ? "row"
        : shape === "box" && (cw < 480 || ch < 400) ? "grid"
        : shape === "wide" || shape === "strip" ? "side"
        : "stack"

    Component.onCompleted: HueBridge.refCount++
    Component.onDestruction: HueBridge.refCount--

    readonly property string screenName: QsWindow.window?.screen?.name ?? ""

    // The lights panel on this screen (one for the shell, HueFallback).
    function more(): void {
        HueBridge.openPanel(screenName);
    }

    function openPicker(kind: string, id: string, name: string): void {
        HueBridge.picker = { kind: kind, id: id, name: name, screen: screenName };
    }

    // States: no binary, bridge silent, nothing yet, no rooms.
    Column {
        anchors.centerIn: parent
        width: parent.width
        visible: !HueBridge.available || !HueBridge.loaded || HueBridge.rooms.length === 0
        spacing: root.gap / 2

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "lightbulb"
            size: Math.min(root.t2 * 2, root.ch * 0.4)
            color: root.theme.color.soft
        }

        ThemedText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: !HueBridge.available ? I18n.tr("hue.noBinary") : HueBridge.loaded ? I18n.tr("hue.noRooms") : HueBridge.lastError ? I18n.tr("hue.noBridge") : I18n.tr("hue.loading")
            font.pixelSize: root.t3
            color: root.theme.color.soft
        }
    }

    // tiny: one tile.
    Toggle {
        visible: root.mode === "tiny" && HueBridge.rooms.length > 0
        anchors.fill: parent
        icon: "lightbulb"
        label: I18n.tr("module.hue")
        sub: I18n.tr("hue.rooms", { on: HueBridge.roomsOn, total: HueBridge.rooms.length })
        on: HueBridge.roomsOn > 0
        onTapped: root.more()
    }

    // A: room tiles; More in the last slot when asked.
    component Rooms: Grid {
        id: rooms

        property var m
        property int cols: 2
        property bool withMore: true
        // Tiles select (B shown) rather than toggle.
        property bool selecting: false
        readonly property int capacity: Math.max(1, cols * Math.max(1, Math.floor((height + spacing) / (rooms.m.hit + spacing))))
        // More last: always when the room isn't shown beside (it's the only
        // way to the rest), else only when the rooms overflow.
        // Ids only: toggling a room doesn't rebuild the tile being tapped.
        readonly property string idKey: HueBridge.rooms.map(r => r.id).join(",")
        readonly property var list: {
            const all = idKey ? idKey.split(",") : [];
            const needMore = withMore && (!selecting || all.length > capacity);
            if (!needMore)
                return all.slice(0, capacity);
            return all.slice(0, Math.max(0, capacity - 1)).concat(["more"]);
        }
        readonly property int lines: Math.max(1, Math.ceil(list.length / cols))

        columns: cols
        spacing: rooms.m.gap

        Repeater {
            model: rooms.list

            Item {
                id: slot

                required property string modelData
                readonly property bool isMore: modelData === "more"
                readonly property var room: isMore ? null : HueBridge.room(modelData)
                // Modulaire's tile is a lever already: one action (toggle and
                // select).
                readonly property bool dual: rooms.selecting && width >= 240 && rooms.m.look !== "modulaire"
                readonly property bool isSelected: rooms.selecting && !isMore && rooms.m.selected?.id === modelData

                width: (rooms.width - (rooms.cols - 1) * rooms.spacing) / rooms.cols
                height: Math.max(rooms.m.hit, (rooms.height - (rooms.lines - 1) * rooms.spacing) / rooms.lines)

                // Dual tiles leave the switch its own room on the right.
                Toggle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: slot.dual ? sw.left : parent.right
                    anchors.rightMargin: slot.dual ? 4 : 0
                    icon: slot.isMore ? "more_horiz" : HueBridge.roomIcon(slot.room?.cls ?? "")
                    label: slot.isMore ? I18n.tr("hue.more") : slot.room?.name ?? ""
                    sub: slot.isMore ? I18n.tr("hue.moreSub") : slot.room?.on ? I18n.percent(slot.room.brightness / 100) : I18n.tr("hue.off")
                    on: !slot.isMore && !!slot.room?.on
                    plain: slot.isMore
                    onTapped: {
                        const m = rooms.m, id = slot.modelData, selecting = rooms.selecting;
                        if (slot.isMore)
                            m.more();
                        else if (slot.dual)
                            m.selectedId = id;
                        else {
                            if (selecting)
                                m.selectedId = id;
                            Qt.callLater(HueBridge.toggleRoom, id);
                        }
                    }
                }

                // Selection outline.
                Rectangle {
                    visible: slot.isSelected
                    anchors.fill: parent
                    anchors.margins: -5
                    radius: rooms.m.theme.radius.control * 2
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.alpha(rooms.m.theme.color.ink, 0.55)
                }

                // The room's color while it's on.
                Rectangle {
                    visible: !slot.isMore && !!slot.room?.on && !!slot.room?.color
                    x: slot.dual ? parent.width - sw.width - width - 14 : parent.width - width - 12
                    y: 12
                    width: 12
                    height: 12
                    radius: 6
                    color: slot.room?.color || "transparent"
                    border.width: 1
                    border.color: Qt.alpha("black", 0.3)
                }

                // Dual tiles: the switch on the right toggles.
                HueParts.Switch {
                    id: sw
                    visible: slot.dual
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    on: !slot.isMore && !!slot.room?.on
                    onAccent: rooms.m.look === "classic" && on
                    onToggled: Qt.callLater(HueBridge.toggleRoom, slot.modelData)
                }
            }
        }
    }

    // B: the selected room.
    component Detail: Column {
        id: detail

        property var m
        property bool withMore: true
        readonly property var room: detail.m.selected
        readonly property real row: detail.m.hit
        // The color row is lower (its swatches reach `hit` by their touch
        // area): it fits with one row of scenes in a 4 × 2 cell.
        readonly property real colorH: Math.min(row, 56)
        readonly property bool colorRow: height - header.height - row * 2 - colorH - spacing * 3 >= 0
        readonly property real scenesRoom: height - header.height - row - (colorRow ? colorH : 0) - spacing * (colorRow ? 3 : 2)
        readonly property int sceneCols: width >= 420 ? 3 : 2
        readonly property int sceneRows: Math.max(0, Math.floor((scenesRoom + 10) / (row + 10)))
        readonly property var scenes: {
            const all = (room?.scenes ?? []).slice();
            const active = HueBridge.activeScene[room?.id ?? ""];
            all.sort((a, b) => (b.id === active) - (a.id === active));
            const capacity = sceneCols * sceneRows;
            if (all.length <= capacity || !withMore)
                return all.slice(0, capacity);
            return all.slice(0, Math.max(0, capacity - 1)).concat([{ more: true }]);
        }

        spacing: detail.m.gap * 0.6
        visible: !!room

        Row {
            id: header
            width: parent.width
            spacing: detail.m.gap / 2

            ThemedText {
                anchors.baseline: lampCount.baseline
                width: Math.min(implicitWidth, parent.width - lampCount.width - parent.spacing)
                elide: Text.ElideRight
                text: detail.room?.name ?? ""
                font.pixelSize: detail.m.t2
                font.weight: Font.DemiBold
            }

            ThemedText {
                id: lampCount
                text: detail.room ? I18n.tr("hue.lamps", { on: detail.room.lights.filter(id => HueBridge.lights[id]?.on).length, total: detail.room.lights.length }) : ""
                font.pixelSize: detail.m.t4
                color: detail.m.theme.color.soft
            }
        }

        // Brightness (dimmed while off; moving it lights the room).
        Item {
            width: parent.width
            height: detail.row

            Icon {
                id: sunIcon
                anchors.verticalCenter: parent.verticalCenter
                name: "light_mode"
                size: Math.min(28, detail.row * 0.5)
                color: detail.m.theme.color.soft
            }

            Slider {
                anchors.left: sunIcon.right
                anchors.leftMargin: detail.m.gap
                anchors.right: briValue.left
                anchors.rightMargin: detail.m.gap
                anchors.verticalCenter: parent.verticalCenter
                value: (detail.room?.brightness ?? 0) / 100
                dimmed: !detail.room?.on
                onMoved: value => HueBridge.setRoomBrightness(detail.room.id, Math.max(1, Math.round(value * 100)))
            }

            ThemedText {
                id: briValue
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: detail.m.t3 * 3.4
                horizontalAlignment: Text.AlignRight
                text: detail.room?.on ? I18n.percent(detail.room.brightness / 100) : I18n.tr("hue.off")
                font.pixelSize: detail.m.t3
                font.features: ({ "tnum": 1 })
            }
        }

        // Current color (opens the picker), then the favorites.
        Row {
            visible: detail.colorRow
            height: detail.colorH
            spacing: Math.max(6, detail.m.gap * 0.6)

            HueParts.Swatch {
                anchors.verticalCenter: parent.verticalCenter
                size: detail.colorH
                swatchColor: detail.room?.color || "#FFE9D2"
                onTapped: detail.m.openPicker("room", detail.room.id, detail.room.name)

                Icon {
                    anchors.centerIn: parent
                    name: "palette"
                    size: parent.width * 0.45
                    color: "#99000000"
                }
            }

            Repeater {
                // As many favorites as the width holds.
                model: HueBridge.favorites.slice(0, Math.max(0, Math.floor((detail.width - detail.colorH) / (Math.min(detail.row * 0.62, 40) + Math.max(6, detail.m.gap * 0.6)))))

                HueParts.Swatch {
                    required property var modelData
                    anchors.verticalCenter: parent.verticalCenter
                    size: Math.min(detail.row * 0.62, 40)
                    swatchColor: modelData.color
                    onTapped: HueBridge.setRoomColor(detail.room.id, modelData.color)
                }
            }
        }

        // Scenes (the active one first; More when they overflow).
        Grid {
            width: parent.width
            columns: detail.sceneCols
            spacing: 10

            Repeater {
                model: detail.scenes

                HueParts.Key {
                    required property var modelData
                    width: (parent.width - (detail.sceneCols - 1) * 10) / detail.sceneCols
                    height: detail.row
                    text: modelData.more ? I18n.tr("hue.more") : modelData.name
                    icon: modelData.more ? "more_horiz" : ""
                    active: !modelData.more && HueBridge.activeScene[detail.room?.id ?? ""] === modelData.id
                    textSize: Math.min(detail.m.t3, 18)
                    onTapped: {
                        const room = detail.room?.id ?? "", scene = modelData.id;
                        if (modelData.more)
                            detail.m.more();
                        else
                            Qt.callLater(HueBridge.startScene, room, scene);
                    }
                }
            }
        }
    }

    // C: the selected room's lights.
    component Lamps: Flickable {
        id: lamps

        property var m
        readonly property var ids: lamps.m.selected?.lights ?? []

        clip: true
        contentHeight: lampColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: lampColumn
            width: lamps.width
            spacing: 4

            Repeater {
                model: lamps.ids

                Item {
                    id: lamp

                    required property var modelData
                    readonly property var light: HueBridge.lights[modelData] ?? null

                    width: lampColumn.width
                    height: lamps.m.hit
                    opacity: lamp.light?.reachable ? 1 : 0.45

                    Rectangle {
                        anchors.fill: parent
                        radius: lamps.m.theme.radius.control
                        color: lampArea.containsMouse ? lamps.m.theme.color.surface2 : "transparent"
                    }

                    Rectangle {
                        id: lampDot
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8
                        width: 12
                        height: 12
                        radius: 6
                        color: lamp.light?.on ? (lamp.light.color || "#FFE9D2") : Qt.alpha(lamps.m.theme.color.ink, 0.15)
                    }

                    Column {
                        anchors.left: lampDot.right
                        anchors.leftMargin: 12
                        anchors.right: lampSwitch.left
                        anchors.verticalCenter: parent.verticalCenter

                        ThemedText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: lamp.light?.name ?? ""
                            font.pixelSize: lamps.m.t3
                        }

                        ThemedText {
                            text: !lamp.light?.reachable ? I18n.tr("hue.unreachable") : lamp.light.on ? I18n.percent(lamp.light.brightness / 100) : I18n.tr("hue.offLamp")
                            font.pixelSize: lamps.m.t4
                            color: lamps.m.theme.color.soft
                        }
                    }

                    MouseArea {
                        id: lampArea
                        anchors.fill: parent
                        anchors.rightMargin: lampSwitch.width
                        hoverEnabled: true
                        enabled: !!lamp.light?.reachable
                        cursorShape: Qt.PointingHandCursor
                        onClicked: lamps.m.openPicker("light", lamp.modelData, lamp.light.name)
                    }

                    HueParts.Switch {
                        id: lampSwitch
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        on: !!lamp.light?.on
                        enabled: !!lamp.light?.reachable
                        onToggled: Qt.callLater(HueBridge.toggleLight, lamp.modelData)
                    }
                }
            }
        }
    }

    // narrow / strip / small box: rooms only, More last.
    Rooms {
        visible: root.mode === "list" || root.mode === "row" || root.mode === "grid"
        m: root
        anchors.fill: parent
        cols: root.mode === "list" ? 1 : root.mode === "grid" ? 2 : Math.max(1, Math.min(HueBridge.rooms.length + 1, Math.floor((root.cw + root.gap) / (140 + root.gap))))
    }

    // box / tall: rooms on top, the room under.
    Column {
        visible: root.mode === "stack"
        anchors.fill: parent
        spacing: root.gap

        Rooms {
            id: stackRooms
            m: root
            width: parent.width
            height: root.shape === "tall" ? Math.min(parent.height * 0.45, HueBridge.rooms.length * (root.hit + root.gap)) : Math.min(parent.height * 0.42, Math.ceil(HueBridge.rooms.length / cols) * (root.hit + root.gap))
            cols: root.shape === "tall" ? 1 : root.cw >= 700 ? 4 : 2
            selecting: true
        }

        Detail {
            m: root
            width: parent.width
            height: parent.height - stackRooms.height - parent.spacing
        }
    }

    // wide: rooms left, the room right.
    Row {
        visible: root.mode === "side"
        anchors.fill: parent
        spacing: root.gap * 1.5

        Rooms {
            m: root
            width: parent.width * 0.46
            height: parent.height
            cols: 2
            selecting: true
        }

        Detail {
            m: root
            width: parent.width * 0.54 - parent.spacing
            height: parent.height
        }
    }

    // Roomy, panel, drawer: rooms, the room, its lights.
    Row {
        visible: root.mode === "three"
        anchors.fill: parent
        spacing: root.gap * 1.5

        Rooms {
            id: threeRooms
            m: root
            width: Math.min(340, parent.width * 0.27)
            height: parent.height
            cols: 1
            withMore: false
            selecting: true
        }

        Detail {
            id: threeDetail
            m: root
            width: (parent.width - threeRooms.width - parent.spacing * 2) * 0.55
            height: parent.height
            withMore: !root.full && !root.drawer
        }

        // Under the close button of the panels.
        Lamps {
            m: root
            y: root.full ? 44 : 0
            width: parent.width - threeRooms.width - threeDetail.width - parent.spacing * 2
            height: parent.height - y
        }
    }
}
