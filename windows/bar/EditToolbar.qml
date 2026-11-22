import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.widgets
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Edit mode toolbar, next to the bar: the selected block (size, zone,
// remove), the palette (add a block), undo/redo, discard, done.
// Keys (the toolbar holds the keyboard while editing): Escape = done,
// Ctrl+Z / Ctrl+Shift+Z = undo / redo, Delete = remove.
PanelWindow {
    id: win

    property var theme: Themes.fallback
    // "top" | "bottom" | "left" | "right" and its thickness: stay clear.
    property string barEdge: "top"
    property int barExtent: 0

    readonly property var selected: BarEditor.selected
    readonly property var selectedEntry: selected ? BarEditor.entryAt(selected) : null
    readonly property string selectedType: selectedEntry ? Registry.typeOf(selectedEntry) : ""

    anchors.top: barEdge !== "bottom"
    anchors.bottom: barEdge === "bottom"
    margins.top: barEdge === "top" ? barExtent + theme.space.s : theme.space.l
    margins.bottom: barEdge === "bottom" ? barExtent + theme.space.s : 0

    implicitWidth: Math.min(content.implicitWidth + theme.space.m * 2, (screen?.width ?? 1600) - 64)
    implicitHeight: content.implicitHeight + theme.space.m * 2
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lc-bar-edit"
    // While editing, keys go to the toolbar (Escape, Ctrl+Z, Delete).
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
        anchors.fill: parent
        radius: win.theme.radius.panel
        color: win.theme.color.surface
        border.width: 1
        border.color: win.theme.color.accent

        Glass {}

        Item {
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                const shift = event.modifiers & Qt.ShiftModifier;
                if (event.key === Qt.Key_Escape)
                    BarEditor.done();
                else if (ctrl && event.key === Qt.Key_Z)
                    shift ? BarEditor.redo() : BarEditor.undo();
                else if (event.key === Qt.Key_Delete && win.selected)
                    BarEditor.remove(win.selected);
                else
                    return;
                event.accepted = true;
            }
        }

        Flow {
            id: content

            x: win.theme.space.m
            y: win.theme.space.m
            width: Math.min(implicitWidth, win.width - win.theme.space.m * 2)
            spacing: win.theme.space.m

            ThemedText {
                height: 32
                text: I18n.tr("edit.title")
                font.weight: Font.DemiBold
            }

            // Selected block.
            ThemedText {
                visible: !win.selected
                height: 32
                text: I18n.tr("edit.hint")
                color: win.theme.color.soft
            }

            Row {
                visible: !!win.selected
                spacing: win.theme.space.s

                ThemedText {
                    height: 32
                    text: win.selectedType ? I18n.tr(`widget.${win.selectedType}`) : ""
                    color: win.theme.color.accent
                    font.weight: Font.DemiBold
                }

                Choice {
                    model: BarEditor.sizes.map(s => ({ value: s, label: I18n.tr(`edit.size.${s}`) }))
                    value: BarEditor.sizeOf(win.selectedEntry)
                    onPicked: value => BarEditor.setSize(win.selected, value)
                }

                Choice {
                    model: BarEditor.zoneNames.map(z => ({ value: z, label: I18n.tr(`settings.zoneShort.${z}`) }))
                    value: win.selected?.zone ?? ""
                    onPicked: value => {
                        if (value !== win.selected.zone)
                            BarEditor.move(win.selected, { screen: win.selected.screen, zone: value, group: -1, index: 0 });
                    }
                }

                ToolButton {
                    text: "✕"
                    onActivated: BarEditor.remove(win.selected)
                }
            }

            // Palette: add a block (to the selected block's zone, else the end).
            Row {
                spacing: win.theme.space.xs

                ThemedText {
                    height: 32
                    text: I18n.tr("settings.addBlock")
                    color: win.theme.color.soft
                }

                Repeater {
                    // Only blocks not on this screen's bar yet.
                    model: Object.keys(Registry.widgets).filter(t => !BarEditor.typesOn(win.screen).includes(t))

                    ToolButton {
                        required property string modelData
                        text: `+ ${I18n.tr(`widget.${modelData}`)}`
                        onActivated: BarEditor.add(win.screen.name, modelData, win.selected?.zone ?? "right")
                    }
                }
            }

            Row {
                spacing: win.theme.space.xs

                ToolButton {
                    text: I18n.tr("edit.undo")
                    enabled: BarEditor.undoStack.length > 0
                    onActivated: BarEditor.undo()
                }
                ToolButton {
                    text: I18n.tr("edit.redo")
                    enabled: BarEditor.redoStack.length > 0
                    onActivated: BarEditor.redo()
                }
                ToolButton {
                    text: I18n.tr("edit.discard")
                    onActivated: BarEditor.discard()
                }
                ToolButton {
                    text: I18n.tr("edit.done")
                    primary: true
                    onActivated: BarEditor.done()
                }
            }
        }
    }

    component ToolButton: Rectangle {
        id: button

        property string text
        property bool primary: false
        signal activated

        readonly property var theme: QsWindow.window?.theme ?? Themes.fallback

        width: label.implicitWidth + theme.space.m * 2
        height: 32
        radius: theme.radius.full
        opacity: enabled ? 1 : 0.4
        color: primary ? theme.color.accent : area.containsMouse ? theme.color.surface3 : theme.color.surface2

        ThemedText {
            id: label
            anchors.centerIn: parent
            text: button.text
            color: button.primary ? button.theme.color.onAccent : button.theme.color.ink
            font.pixelSize: button.theme.font.sizeS
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }
}
