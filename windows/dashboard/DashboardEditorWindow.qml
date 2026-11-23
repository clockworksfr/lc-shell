import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.components
import qs.dashboard
import qs.dashboard.modules
import qs.i18n
import qs.theme

// Dashboard editor, on the "modules" screen itself (design study,
// "Dashboard editor"): the page's cells over a grid; drag a cell to move
// it, its corner to resize it (snapped to the grid; red where it would
// cover another cell); bottom bar: pages, inspector of the selected cell
// (S / M / L, remove), add a module or a window cell, undo / redo,
// discard, done. Over everything (overlay layer) while editing.
PanelWindow {
    id: win

    property var theme

    readonly property var grid: DashboardEditor.grid
    readonly property real barHeight: 88
    // Pointer target size (bigger on touch screens).
    readonly property real handle: Math.max(28, theme.hit)
    readonly property var types: Object.keys(Registry.modules).filter(t => t !== "window" && t !== "notificationSample")
    property bool palette: false

    function cellSize(): var {
        return {
            w: (area.width - 2 * grid.margin - (grid.columns - 1) * grid.gap) / grid.columns,
            h: (area.height - 2 * grid.margin - (grid.rows - 1) * grid.gap) / grid.rows
        };
    }

    // Grid position under a point of the area (rounded to the nearest cell).
    function snap(x: real, y: real): point {
        const s = cellSize();
        return Qt.point(Math.round((x - grid.margin) / (s.w + grid.gap)), Math.round((y - grid.margin) / (s.h + grid.gap)));
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: theme.color.bg
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-dashboard-editor"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    Item {
        id: area

        width: parent.width
        height: parent.height - win.barHeight
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (win.palette)
                    win.palette = false;
                else if (DashboardEditor.selected >= 0)
                    DashboardEditor.selected = -1;
                else
                    DashboardEditor.done();
            } else if (event.key === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)) {
                (event.modifiers & Qt.ShiftModifier) ? DashboardEditor.redo() : DashboardEditor.undo();
            } else if (event.key === Qt.Key_Delete && DashboardEditor.selected >= 0) {
                DashboardEditor.remove(DashboardEditor.selected);
            }
        }

        // Click on the empty grid: deselect.
        MouseArea {
            anchors.fill: parent
            onClicked: DashboardEditor.selected = -1
        }

        // Grid.
        Repeater {
            model: win.grid.columns * win.grid.rows

            Rectangle {
                required property int index
                readonly property var r: Dashboard.rect({ x: index % win.grid.columns, y: Math.floor(index / win.grid.columns), w: 1, h: 1 }, win.grid, area.width, area.height)
                x: r.x
                y: r.y
                width: r.width
                height: r.height
                radius: win.theme.radius.control
                color: "transparent"
                border.width: 1
                border.color: Qt.alpha(win.theme.color.accent, 0.22)
            }
        }

        // Cells.
        Repeater {
            model: DashboardEditor.cells

            Item {
                id: cell

                required property var modelData
                required property int index
                readonly property var rect: Dashboard.rect(modelData, win.grid, area.width, area.height)
                readonly property bool selected: DashboardEditor.selected === index
                readonly property bool frameless: Registry.frameless.includes(modelData.type)
                // Move / resize in progress: target in grid units.
                property var target: null
                property point press
                property bool moved: false

                x: rect.x
                y: rect.y
                width: rect.width
                height: rect.height
                z: selected ? 2 : 1

                Rectangle {
                    anchors.fill: parent
                    radius: win.theme.radius.card
                    // Modules draw their own frame: only the selection here.
                    z: 3
                    color: cell.frameless ? Qt.alpha(win.theme.color.accent, 0.08) : "transparent"
                    border.width: cell.selected ? 3 : 0
                    border.color: win.theme.color.accent
                }

                // The module itself (live), not interactive here.
                Loader {
                    anchors.fill: parent
                    anchors.margins: 0
                    enabled: false
                    active: !cell.frameless
                    source: Registry.url(cell.modelData.type)
                    onLoaded: {
                        item.screen = Qt.binding(() => win.screen);
                        item.options = Qt.binding(() => cell.modelData);
                        if ("type" in item)
                            item.type = Qt.binding(() => cell.modelData.type);
                    }
                }

                // Window cell / label.
                Column {
                    anchors.centerIn: parent
                    visible: cell.frameless
                    spacing: win.theme.space.xs

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "view_quilt"
                        size: 40
                        color: win.theme.color.accent
                    }

                    ThemedText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.tr("dashEdit.windowCell")
                        font.weight: Font.DemiBold
                    }
                }

                // Move.
                MouseArea {
                    anchors.fill: parent
                    cursorShape: pressed && cell.moved ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onPressed: mouse => {
                        cell.press = Qt.point(mouse.x, mouse.y);
                        cell.moved = false;
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        if (!cell.moved && Math.hypot(mouse.x - cell.press.x, mouse.y - cell.press.y) < 6)
                            return;
                        cell.moved = true;
                        DashboardEditor.selected = cell.index;
                        const p = mapToItem(area, mouse.x - cell.press.x, mouse.y - cell.press.y);
                        const g = win.snap(p.x, p.y);
                        cell.target = { x: g.x, y: g.y, w: cell.modelData.w ?? 1, h: cell.modelData.h ?? 1 };
                    }
                    onReleased: {
                        if (cell.moved && cell.target)
                            DashboardEditor.place(cell.index, cell.target);
                        else if (!cell.moved)
                            DashboardEditor.selected = cell.selected ? -1 : cell.index;
                        cell.target = null;
                        cell.moved = false;
                    }
                }

                // Resize (bottom-right corner).
                Rectangle {
                    visible: cell.selected
                    width: win.handle
                    height: win.handle
                    x: parent.width - width / 2 - 4
                    y: parent.height - height / 2 - 4
                    radius: width / 2
                    color: win.theme.color.accent
                    border.width: 2
                    border.color: win.theme.color.bg

                    Icon {
                        anchors.centerIn: parent
                        name: "open_in_full"
                        size: parent.width * 0.55
                        color: win.theme.color.onAccent
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.SizeFDiagCursor
                        onPositionChanged: mouse => {
                            if (!pressed)
                                return;
                            const p = mapToItem(area, mouse.x, mouse.y);
                            const g = win.snap(p.x, p.y);
                            const x = cell.modelData.x ?? 0, y = cell.modelData.y ?? 0;
                            cell.target = { x: x, y: y, w: Math.max(1, g.x - x), h: Math.max(1, g.y - y) };
                        }
                        onReleased: {
                            if (cell.target)
                                DashboardEditor.place(cell.index, cell.target);
                            cell.target = null;
                        }
                    }
                }

                // Where it would land.
                Rectangle {
                    visible: !!cell.target
                    readonly property var r: cell.target ? Dashboard.rect(cell.target, win.grid, area.width, area.height) : ({ x: 0, y: 0, width: 0, height: 0 })
                    readonly property bool ok: !!cell.target && DashboardEditor.fits(cell.target, cell.index)
                    parent: area
                    z: 5
                    x: r.x
                    y: r.y
                    width: r.width
                    height: r.height
                    radius: win.theme.radius.card
                    color: Qt.alpha(ok ? win.theme.color.accent : win.theme.color.urgent, 0.18)
                    border.width: 2
                    border.color: ok ? win.theme.color.accent : win.theme.color.urgent
                }
            }
        }
    }

    // Bottom bar.
    Rectangle {
        id: bottom

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: win.barHeight
        color: win.theme.color.surface
        border.width: 1
        border.color: win.theme.color.line

        readonly property var cell: DashboardEditor.cells[DashboardEditor.selected] ?? null
        readonly property string workspace: Hyprland.monitorFor(win.screen)?.activeWorkspace?.name ?? ""

        // Left: the workspace's preset (pick another, duplicate it, or no
        // dashboard on this workspace).
        Row {
            anchors.left: parent.left
            anchors.leftMargin: win.theme.space.l
            anchors.verticalCenter: parent.verticalCenter
            spacing: win.theme.space.s
            visible: !win.palette

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                label: true
                text: I18n.tr("dashEdit.presetOf", { name: DashboardEditor.workspace })
                color: win.theme.color.soft
            }

            Choice {
                anchors.verticalCenter: parent.verticalCenter
                model: Object.keys(DashboardEditor.pages).sort((a, b) => a.localeCompare(b, undefined, { numeric: true })).map(p => ({ value: p, label: p }))
                value: DashboardEditor.page
                onPicked: value => DashboardEditor.usePreset(value)
            }

            Button {
                anchors.verticalCenter: parent.verticalCenter
                icon: "content_copy"
                text: I18n.tr("dashEdit.duplicate")
                onClicked: DashboardEditor.duplicate()
            }

            Button {
                anchors.verticalCenter: parent.verticalCenter
                icon: "delete"
                text: I18n.tr("dashEdit.removeFromWorkspace")
                onClicked: DashboardEditor.removeFromWorkspace()
            }
        }

        // Center: inspector of the selected cell, or the palette.
        Row {
            anchors.centerIn: parent
            spacing: win.theme.space.s
            visible: !win.palette && !!bottom.cell

            ThemedText {
                anchors.verticalCenter: parent.verticalCenter
                text: bottom.cell ? (bottom.cell.type === "window" ? I18n.tr("dashEdit.windowCell") : I18n.tr(`module.${bottom.cell.type}`)) : ""
                font.weight: Font.DemiBold
            }

            Repeater {
                model: ["S", "M", "L"]

                Button {
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property var size: DashboardEditor.sizes[modelData]
                    primary: !!bottom.cell && bottom.cell.w === size.w && bottom.cell.h === size.h
                    text: `${modelData} · ${size.w}×${size.h}`
                    onClicked: DashboardEditor.resizeTo(DashboardEditor.selected, modelData)
                }
            }

            Button {
                anchors.verticalCenter: parent.verticalCenter
                icon: "delete"
                text: I18n.tr("dashEdit.remove")
                onClicked: DashboardEditor.remove(DashboardEditor.selected)
            }
        }

        Flow {
            anchors.left: parent.left
            anchors.right: actions.left
            anchors.margins: win.theme.space.l
            anchors.verticalCenter: parent.verticalCenter
            spacing: win.theme.space.s
            visible: win.palette

            Repeater {
                model: win.types

                Button {
                    required property string modelData
                    text: I18n.tr(`module.${modelData}`)
                    onClicked: {
                        DashboardEditor.add(modelData);
                        win.palette = false;
                    }
                }
            }
        }

        // Right: add, undo / redo, discard, done.
        Row {
            id: actions

            anchors.right: parent.right
            anchors.rightMargin: win.theme.space.l
            anchors.verticalCenter: parent.verticalCenter
            spacing: win.theme.space.s

            Button {
                icon: win.palette ? "close" : "add"
                text: win.palette ? I18n.tr("dashEdit.closePalette") : I18n.tr("dashEdit.addModule")
                onClicked: win.palette = !win.palette
            }

            Button {
                visible: !win.palette
                icon: "view_quilt"
                text: I18n.tr("dashEdit.addWindowCell")
                onClicked: DashboardEditor.add("window")
            }

            Button {
                icon: "undo"
                text: ""
                enabled: DashboardEditor.undoStack.length > 0
                onClicked: DashboardEditor.undo()
            }

            Button {
                icon: "redo"
                text: ""
                enabled: DashboardEditor.redoStack.length > 0
                onClicked: DashboardEditor.redo()
            }

            Button {
                text: I18n.tr("edit.discard")
                onClicked: DashboardEditor.discard()
            }

            Button {
                primary: true
                icon: "check"
                text: I18n.tr("edit.done")
                onClicked: DashboardEditor.done()
            }
        }
    }
}
