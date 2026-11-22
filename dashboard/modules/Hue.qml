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
        // Compact rows (52 px) where the room isn't shown beside: two rows
        // of rooms even in a one-unit-high cell.
        readonly property real rowMin: selecting ? rooms.m.hit : 52
        readonly property int capacity: Math.max(1, cols * Math.max(1, Math.floor((height + spacing) / (rowMin + spacing))))
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
                height: Math.max(rooms.rowMin, (rooms.height - (rooms.lines - 1) * rooms.spacing) / rooms.lines)

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
                    // Matrix: inside the pill, at its right end; else the tile's
                    // corner.
                    readonly property bool inPill: rooms.m.look === "matrix"
                    x: slot.dual ? parent.width - sw.width - width - (inPill ? 18 : 14) : parent.width - width - (inPill ? 12 : 12)
                    y: inPill ? (parent.height - height) / 2 : 12
                    width: inPill ? 8 : 12
                    height: width
                    radius: width / 2
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
            // Lights not shown here (withMore): More is always the last slot,
            // even when the scenes fit or there are none.
            const capacity = sceneCols * Math.max(withMore ? 1 : 0, sceneRows);
            if (!withMore)
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
            x: 3
            height: detail.colorH
            spacing: Math.max(10, detail.m.gap * 0.8)

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
                model: HueBridge.favorites.slice(0, Math.max(0, Math.floor((detail.width - detail.colorH - 6) / (Math.min(detail.row * 0.62, 40) + Math.max(10, detail.m.gap * 0.8)))))

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
            spacing: 6

            Repeater {
                model: lamps.ids

                Item {
                    id: lamp

                    required property var modelData
                    readonly property var light: HueBridge.lights[modelData] ?? null

                    width: lampColumn.width
                    height: Math.max(Math.min(lamps.m.hit, 56), 50)
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
                            font.pixelSize: Math.min(lamps.m.t3, 17)
                        }

                        ThemedText {
                            text: !lamp.light?.reachable ? I18n.tr("hue.unreachable") : lamp.light.on ? I18n.percent(lamp.light.brightness / 100) : I18n.tr("hue.offLamp")
                            font.pixelSize: Math.min(lamps.m.t4, 13)
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
        cols: root.mode === "list" ? 1 : root.mode === "grid" ? 2 : Math.max(1, Math.min(HueBridge.rooms.length + 1, Math.floor((root.cw + root.gap) / ((root.look === "matrix" ? 120 : 140) + root.gap))))
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

    // Roomy, panel, drawer: three columns with their titles. Rooms as a
    // list (the one shown in the middle is highlighted, an accent bar on
    // its left; the switch toggles), the room's sections (brightness,
    // color, scenes, scrolling), its lights.
    component SectionLabel: ThemedText {
        property var m
        label: true
        font.pixelSize: Math.min(m.t4, 12)
        font.letterSpacing: 1
        font.capitalization: Font.AllUppercase
        color: m.theme.color.soft
    }

    component RoomList: Flickable {
        id: roomList

        property var m
        readonly property real rowH: Math.max(roomList.m.hit, 58)

        clip: true
        contentHeight: roomColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: roomColumn
            width: roomList.width
            spacing: 8

            SectionLabel {
                m: roomList.m
                text: I18n.tr("hue.roomsTitle")
                bottomPadding: 4
            }

            Repeater {
                model: HueBridge.rooms.map(r => r.id).join(",").split(",").filter(id => id)

                Rectangle {
                    id: roomRow

                    required property string modelData
                    readonly property var room: HueBridge.room(modelData)
                    readonly property bool selected: roomList.m.selected?.id === modelData

                    width: roomColumn.width
                    height: roomList.rowH
                    radius: roomList.m.theme.radius.control * 1.5
                    color: selected ? roomList.m.theme.color.surface2 : rowArea.containsMouse ? Qt.alpha(roomList.m.theme.color.surface2, 0.5) : "transparent"
                    border.width: selected ? 1 : 0
                    border.color: roomList.m.theme.color.line

                    // Shown in the middle.
                    Rectangle {
                        visible: roomRow.selected
                        x: 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3
                        height: parent.height * 0.6
                        radius: 1.5
                        color: roomList.m.theme.color.accent
                    }

                    Rectangle {
                        id: roomBadge
                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 36
                        height: 36
                        radius: 18
                        color: roomRow.room?.on ? Qt.alpha(roomRow.room.color || "#FFE9D2", 0.25) : roomList.m.theme.color.surface3

                        Icon {
                            anchors.centerIn: parent
                            name: HueBridge.roomIcon(roomRow.room?.cls ?? "")
                            size: 20
                            color: roomRow.room?.on ? (roomRow.room.color || roomList.m.theme.color.ink) : roomList.m.theme.color.soft
                        }
                    }

                    Column {
                        anchors.left: roomBadge.right
                        anchors.leftMargin: 12
                        anchors.right: roomSwitch.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        ThemedText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: roomRow.room?.name ?? ""
                            font.pixelSize: Math.min(roomList.m.t3, 17)
                            font.weight: roomRow.selected ? Font.DemiBold : Font.Normal
                        }

                        ThemedText {
                            width: parent.width
                            elide: Text.ElideRight
                            text: roomRow.room ? `${roomRow.room.on ? I18n.percent(roomRow.room.brightness / 100) : I18n.tr("hue.off")} · ${I18n.plural("hue.lampCount", roomRow.room.lights.length).replace("{n}", roomRow.room.lights.length)}` : ""
                            font.pixelSize: Math.min(roomList.m.t4, 13)
                            color: roomList.m.theme.color.soft
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        anchors.rightMargin: roomSwitch.width
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: roomList.m.selectedId = roomRow.modelData
                    }

                    HueParts.Switch {
                        id: roomSwitch
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        on: !!roomRow.room?.on
                        onToggled: Qt.callLater(HueBridge.toggleRoom, roomRow.modelData)
                    }
                }
            }

            HueParts.Key {
                visible: HueBridge.roomsOn > 0
                width: roomColumn.width
                height: Math.max(40, roomList.m.hit * 0.7)
                text: I18n.tr("hue.allOff")
                icon: "power_settings_new"
                textSize: roomList.m.t4 * 1.1
                onTapped: Qt.callLater(HueBridge.allOff)
            }
        }
    }

    component RoomSections: Flickable {
        id: sections

        property var m
        readonly property var room: sections.m.selected
        readonly property real row: Math.max(sections.m.hit, 44)
        readonly property int sceneCols: width >= 420 ? 3 : 2
        readonly property var scenes: {
            const all = (room?.scenes ?? []).slice();
            const active = HueBridge.activeScene[room?.id ?? ""];
            all.sort((a, b) => (b.id === active) - (a.id === active));
            return all;
        }

        clip: true
        contentHeight: sectionColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: sectionColumn
            width: sections.width
            spacing: sections.m.gap

            // The room, its lights on on the right (design: HHEAD).
            Item {
                width: parent.width
                height: roomTitle.implicitHeight

                ThemedText {
                    id: roomTitle
                    width: parent.width - lampsCount.width - 10
                    elide: Text.ElideRight
                    text: sections.room?.name ?? ""
                    font.pixelSize: Math.min(sections.m.t2, 28)
                    font.weight: Font.DemiBold
                }

                ThemedText {
                    id: lampsCount
                    anchors.right: parent.right
                    anchors.baseline: roomTitle.baseline
                    text: sections.room ? I18n.tr("hue.lamps", { on: sections.room.lights.filter(id => HueBridge.lights[id]?.on).length, total: sections.room.lights.length }) : ""
                    font.pixelSize: sections.m.t4
                    color: sections.m.theme.color.soft
                }
            }

            SectionLabel {
                m: sections.m
                text: I18n.tr("hue.brightness")
            }

            Item {
                width: parent.width
                height: sections.row

                Slider {
                    anchors.left: parent.left
                    anchors.right: briText.left
                    anchors.rightMargin: sections.m.gap
                    anchors.verticalCenter: parent.verticalCenter
                    value: (sections.room?.brightness ?? 0) / 100
                    dimmed: !sections.room?.on
                    onMoved: value => HueBridge.setRoomBrightness(sections.room.id, Math.max(1, Math.round(value * 100)))
                }

                ThemedText {
                    id: briText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: sections.m.t3 * 3.4
                    horizontalAlignment: Text.AlignRight
                    text: sections.room?.on ? I18n.percent(sections.room.brightness / 100) : I18n.tr("hue.off")
                    font.pixelSize: Math.min(sections.m.t3, 17)
                    font.features: ({ "tnum": 1 })
                }
            }

            SectionLabel {
                m: sections.m
                text: I18n.tr("hue.color")
            }

            // Room for the halos (3 px around each swatch).
            Flow {
                width: parent.width - 6
                x: 3
                topPadding: 3
                bottomPadding: 3
                spacing: 14

                HueParts.Swatch {
                    size: 44
                    swatchColor: sections.room?.color || "#FFE9D2"
                    onTapped: sections.m.openPicker("room", sections.room.id, sections.room.name)

                    Icon {
                        anchors.centerIn: parent
                        name: "palette"
                        size: 20
                        color: "#99000000"
                    }
                }

                Repeater {
                    model: HueBridge.favorites

                    HueParts.Swatch {
                        required property var modelData
                        size: 36
                        swatchColor: modelData.color
                        onTapped: HueBridge.setRoomColor(sections.room.id, modelData.color)
                    }
                }
            }

            SectionLabel {
                m: sections.m
                visible: sections.scenes.length > 0
                text: I18n.tr("hue.scenesCount", { n: sections.scenes.length })
            }

            Grid {
                width: parent.width
                columns: sections.sceneCols
                spacing: 8

                Repeater {
                    model: sections.scenes

                    HueParts.Key {
                        required property var modelData
                        width: (parent.width - (sections.sceneCols - 1) * 8) / sections.sceneCols
                        height: Math.max(40, sections.m.hit * 0.7)
                        text: modelData.name
                        active: HueBridge.activeScene[sections.room?.id ?? ""] === modelData.id
                        textSize: Math.min(sections.m.t3, 15)
                        onTapped: {
                            const room = sections.room?.id ?? "", scene = modelData.id;
                            Qt.callLater(HueBridge.startScene, room, scene);
                        }
                    }
                }
            }
        }
    }

    Row {
        visible: root.mode === "three"
        anchors.fill: parent
        anchors.topMargin: root.full ? 8 : 0
        spacing: root.gap * 2

        RoomList {
            id: threeRooms
            m: root
            width: Math.min(320, parent.width * 0.3)
            height: parent.height
        }

        Rectangle {
            width: 1
            height: parent.height
            color: root.theme.color.line
        }

        RoomSections {
            id: threeDetail
            m: root
            width: (parent.width - threeRooms.width - 2 - parent.spacing * 4) * 0.58
            height: parent.height
        }

        Rectangle {
            width: 1
            height: parent.height
            color: root.theme.color.line
        }

        // Its lights (under the close button of the panels).
        Column {
            width: parent.width - threeRooms.width - threeDetail.width - 2 - parent.spacing * 4
            height: parent.height
            spacing: 8

            SectionLabel {
                m: root
                width: parent.width
                elide: Text.ElideRight
                text: I18n.tr("hue.lightsOf", { name: root.selected?.name ?? "" })
                bottomPadding: 4
            }

            Lamps {
                m: root
                width: parent.width
                height: parent.height - y
            }
        }
    }
}
