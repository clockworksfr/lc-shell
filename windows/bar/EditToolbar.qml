import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.widgets
import qs.components
import qs.i18n
import qs.services
import qs.theme

// Edit mode toolbar, next to the bar: actions (undo / redo, discard,
// done), the selected widget's inspector (sizes as live previews, zone,
// send to another screen, remove), the palette (widgets not on the bar,
// with previews and a search).
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

        Column {
            id: content

            x: win.theme.space.m
            y: win.theme.space.m
            width: Math.min(implicitWidth, win.width - win.theme.space.m * 2)
            spacing: win.theme.space.m

            // Title, hint or the selected widget's inspector; actions.
            Row {
                spacing: win.theme.space.m

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.tr("edit.title")
                    font.weight: Font.DemiBold
                }

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !win.selected
                    text: I18n.tr("edit.hint")
                    color: win.theme.color.soft
                }

                Item {
                    width: win.theme.space.l
                    height: 1
                }

                Button {
                    icon: "undo"
                    enabled: BarEditor.undoStack.length > 0
                    onClicked: BarEditor.undo()
                }
                Button {
                    icon: "redo"
                    enabled: BarEditor.redoStack.length > 0
                    onClicked: BarEditor.redo()
                }
                Button {
                    text: I18n.tr("edit.discard")
                    onClicked: BarEditor.discard()
                }
                Button {
                    primary: true
                    icon: "check"
                    text: I18n.tr("edit.done")
                    onClicked: BarEditor.done()
                }
            }

            // Inspector: sizes as live previews, zone, other screens, remove.
            Row {
                visible: !!win.selected
                spacing: win.theme.space.m

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: win.selectedType ? I18n.tr(`widget.${win.selectedType}`) : ""
                    color: win.theme.color.accent
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: BarEditor.sizes

                    Rectangle {
                        id: sizeCard

                        required property string modelData
                        readonly property bool current: BarEditor.sizeOf(win.selectedEntry) === modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(preview.width, sizeLabel.implicitWidth) + win.theme.space.m * 2
                        height: preview.height + sizeLabel.implicitHeight + win.theme.space.s * 3
                        radius: win.theme.radius.tile
                        color: current ? Qt.alpha(win.theme.color.accent, 0.16) : sizeArea.containsMouse ? win.theme.color.surface3 : win.theme.color.surface2
                        border.width: current ? 1 : 0
                        border.color: win.theme.color.accent

                        WidgetPreview {
                            id: preview
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: win.theme.space.s
                            type: win.selectedType
                            size: sizeCard.modelData
                        }

                        ThemedText {
                            id: sizeLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: win.theme.space.s
                            label: true
                            text: I18n.tr(`edit.size.${sizeCard.modelData}`)
                            font.pixelSize: win.theme.font.sizeS
                            color: win.theme.color.soft
                        }

                        MouseArea {
                            id: sizeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarEditor.setSize(win.selected, sizeCard.modelData)
                        }
                    }
                }

                Choice {
                    anchors.verticalCenter: parent.verticalCenter
                    model: BarEditor.zoneNames.map(z => ({ value: z, label: I18n.tr(`settings.zoneShort.${z}`) }))
                    value: win.selected?.zone ?? ""
                    onPicked: value => {
                        if (value !== win.selected.zone)
                            BarEditor.move(win.selected, { screen: win.selected.screen, zone: value, group: -1, index: 0 });
                    }
                }

                // Other screens with a bar: send the widget there.
                Repeater {
                    model: Quickshell.screens.filter(s => s.name !== win.screen?.name && (Config.forScreen(s).mode ?? "normal") === "normal" && !!Config.forScreen(s).bar)

                    Button {
                        required property ShellScreen modelData
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "monitor"
                        text: I18n.tr("edit.sendTo", { screen: modelData.name })
                        onClicked: BarEditor.sendTo(win.selected, modelData.name)
                    }
                }

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "delete"
                    text: I18n.tr("dashEdit.remove")
                    onClicked: BarEditor.remove(win.selected)
                }
            }

            // Palette: widgets not on this bar, with a preview; click adds
            // to the selected widget's zone (else the end).
            Row {
                spacing: win.theme.space.s

                TextField {
                    id: search
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 180
                    placeholder: I18n.tr("edit.searchWidget")
                    onEdited: text => win.query = text
                }

                Repeater {
                    model: Object.keys(Registry.widgets).filter(t => !BarEditor.typesOn(win.screen).includes(t) && I18n.tr(`widget.${t}`).toLowerCase().includes(win.query.trim().toLowerCase()))

                    Rectangle {
                        id: chip

                        required property string modelData

                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(chipPreview.width, chipName.implicitWidth) + win.theme.space.m * 2
                        height: chipPreview.height + chipName.implicitHeight + win.theme.space.s * 3
                        radius: win.theme.radius.tile
                        color: chipArea.containsMouse ? win.theme.color.surface3 : win.theme.color.surface2

                        WidgetPreview {
                            id: chipPreview
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: win.theme.space.s
                            type: chip.modelData
                            size: "normal"
                        }

                        ThemedText {
                            id: chipName
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: win.theme.space.s
                            text: `+ ${I18n.tr(`widget.${chip.modelData}`)}`
                            font.pixelSize: win.theme.font.sizeS
                        }

                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BarEditor.add(win.screen.name, chip.modelData, win.selected?.zone ?? "right")
                        }
                    }
                }

                ThemedText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !Object.keys(Registry.widgets).some(t => !BarEditor.typesOn(win.screen).includes(t))
                    text: I18n.tr("edit.allPlaced")
                    color: win.theme.color.soft
                }
            }
        }
    }

    property string query: ""

    // A widget drawn for a preview (not interactive), at a size.
    component WidgetPreview: Item {
        id: preview

        property string type
        property string size: "normal"

        width: Math.min(loader.implicitWidth, 260)
        height: Math.max(loader.implicitHeight, 20)
        clip: true

        Loader {
            id: loader

            enabled: false
            source: preview.type ? Registry.url(preview.type) : ""
            onLoaded: {
                item.screen = Qt.binding(() => win.screen);
                item.options = Qt.binding(() => ({ size: preview.size }));
                if ("crossSize" in item)
                    item.crossSize = 24;
            }
        }
    }
}
